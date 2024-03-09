cmake_minimum_required(VERSION 3.17)

# renovate datasource=custom.libev-attic depName=libev
set(LIBEV_VERSION "4.33")
project(libev VERSION ${LIBEV_VERSION} LANGUAGES C)

set(CMAKE_VERBOSE_MAKEFILE ON)
set(CMAKE_CONFIGURATION_TYPES "Debug;Release;RelWithDebInfo;MinSizeRel")
if(CMAKE_GENERATOR MATCHES "Ninja Multi-Config")
    set(CMAKE_DEFAULT_BUILD_TYPE "Release")
endif()

if(POLICY CMP0135)
    cmake_policy(SET CMP0135 NEW)
endif()

if(BUILD_SHARED_LIBS)
    set(libev_BUILD_SHARED_LIBS_DEFAULT ON)
else()
    set(libev_BUILD_SHARED_LIBS_DEFAULT OFF)
endif()

option(libev_BUILD_SHARED_LIBS "Build shared libraries" ${libev_BUILD_SHARED_LIBS_DEFAULT})

add_library(ev)
add_library(ev::ev ALIAS ev)

target_compile_definitions(ev PRIVATE $<$<CONFIG:Debug>:EV_VERIFY=3>)
target_compile_features(ev PRIVATE c_std_99)

include(CMakePackageConfigHelpers)
include(CheckFunctionExists)
include(CheckIncludeFiles)
include(CheckLibraryExists)
include(CheckTypeSize)
include(FetchContent)
include(GNUInstallDirs)

function(check_and_define items check_function)
    foreach(item ${${items}})
        string(TOUPPER ${item} item_upper)
        string(MAKE_C_IDENTIFIER ${item_upper} item_upper)
        if(${check_function} STREQUAL "check_include_files")
            check_include_files(${item} "HAVE_${item_upper}")
        elseif(${check_function} STREQUAL "check_function_exists")
            check_function_exists(${item} "HAVE_${item_upper}")
        endif()
    endforeach()
endfunction()

# AC_INCLUDES_DEFAULT (implicit)
set(
    HEADERS
    # AC_INCLUDES_DEFAULT (implicit)
    "sys/types.h" "sys/stat.h" "stdlib.h" "string.h" "memory.h" "strings.h" "inttypes.h" "stdint.h" "unistd.h"
    # AC_HEADER_STDC (implicit)
    "stdarg.h" "float.h"
    "dlfcn.h"
    # AC_CHECK_HEADERS(sys/inotify.h sys/epoll.h sys/event.h port.h poll.h sys/timerfd.h)
    "sys/inotify.h" "sys/epoll.h" "sys/event.h" "port.h" "poll.h" "sys/timerfd.h"
    # AC_CHECK_HEADERS(sys/select.h sys/eventfd.h sys/signalfd.h linux/aio_abi.h linux/fs.h)
    "sys/select.h" "sys/eventfd.h" "sys/signalfd.h" "linux/aio_abi.h" "linux/fs.h"
    "sys/syscall.h"
)
check_and_define(HEADERS check_include_files)
# HAVE_STDLIB_H AND HAVE_STDARG_H AND HAVE_STRING_H AND HAVE_FLOAT_H - should be true because of c_std_99
set(STDC_HEADERS 1)

set(
    FUNCTIONS
    # AC_CHECK_FUNCS(inotify_init epoll_ctl kqueue port_create poll select eventfd signalfd)
    "inotify_init" "epoll_ctl" "kqueue" "port_create" "poll" "select" "eventfd" "signalfd"
    # AC_CHECK_FUNCS(clock_gettime...)
    "clock_gettime"
    # AC_CHECK_FUNCS(nanosleep...)
    "nanosleep"
    # AC_SEARCH_LIBS(floor...)
    "floor"
)
check_and_define(FUNCTIONS check_function_exists)

# AC_CHECK_FUNCS(clock_gettime...)
if(NOT HAVE_CLOCK_GETTIME)
    if(HAVE_UNISTD_H AND HAVE_SYS_SYSCALL_H)
        set(prog "
            #include <unistd.h>
            #include <sys/syscall.h>
            #include <time.h>

            int main() {
                struct timespec ts;
                int status = syscall (SYS_clock_gettime, CLOCK_REALTIME, &ts);
                return status;
            }
        ")

        try_compile(HAVE_CLOCK_SYSCALL SOURCE_FROM_VAR "__test.c" prog)
        unset(prog)
    endif()

    if(NOT HAVE_CLOCK_SYSCALL)
        unset(HAVE_CLOCK_GETTIME CACHE)
        check_library_exists(rt clock_gettime "" HAVE_CLOCK_GETTIME)
        if(HAVE_CLOCK_GETTIME)
            set(HAVE_LIBRT 1)
        endif()
    endif()
endif()

# AC_CHECK_FUNCS(nanosleep...)
if(NOT HAVE_NANOSLEEP)
    check_library_exists(rt nanosleep "" HAVE_NANOSLEEP_IN_RT)
endif()

if(HAVE_NANOSLEEP_IN_RT)
    set(HAVE_NANOSLEEP 1)
    set(HAVE_LIBRT 1)
endif()

if(HAVE_LIBRT)
    target_link_libraries(ev rt)
endif()

# AC_CHECK_TYPE(__kernel_rwf_t...)
if(HAVE_LINUX_FS_H)
    list(APPEND CMAKE_EXTRA_INCLUDE_FILES "linux/fs.h")
    check_type_size(__kernel_rwf_t KERNEL_RWF_T)
endif()

# AC_SEARCH_LIBS(floor...)
if(NOT HAVE_FLOOR)
    check_library_exists(m floor "" HAVE_FLOOR_IN_LIBM)
endif()

if(HAVE_FLOOR_IN_LIBM)
    set(HAVE_FLOOR 1)
    set(HAVE_LIBM 1)
endif()

if(HAVE_LIBM)
    target_link_libraries(ev m)
endif()

###
set(LT_OBJDIR ".libs/")
set(PACKAGE ${PROJECT_NAME})
set(PACKAGE_BUGREPORT "")
set(PACKAGE_STRING "${PROJECT_NAME} ${PROJECT_VERSION}")
set(PACKAGE_TARNAME ${PROJECT_NAME})
set(PACKAGE_URL "")
set(PACKAGE_VERSION ${PROJECT_VERSION})
###

configure_file(config.h.in ${CMAKE_CURRENT_BINARY_DIR}/config.h)

FetchContent_Declare(ev_ext URL "http://dist.schmorp.de/libev/Attic/libev-${LIBEV_VERSION}.tar.gz" URL_HASH SHA256=507eb7b8d1015fbec5b935f34ebed15bf346bed04a11ab82b8eee848c4205aea)
FetchContent_MakeAvailable(ev_ext)

target_include_directories(ev
    PUBLIC
        $<INSTALL_INTERFACE:include>
        $<BUILD_INTERFACE:${ev_ext_SOURCE_DIR}>
    PRIVATE
        ${ev_ext_SOURCE_DIR}
        ${CMAKE_CURRENT_BINARY_DIR}
)

target_sources(ev PRIVATE ${ev_ext_SOURCE_DIR}/ev.c ${ev_ext_SOURCE_DIR}/event.c)

if(MSVC)
    target_compile_definitions(ev _CRT_SECURE_NO_WARNINGS)
endif()

if(WIN32)
    target_link_libraries(ev Ws2_32)
endif()

set(EV_HEADERS ${ev_ext_SOURCE_DIR}/ev.h ${ev_ext_SOURCE_DIR}/ev++.h ${ev_ext_SOURCE_DIR}/event.h)
set_target_properties(ev PROPERTIES
    VERSION "4.0.0"
    SOVERSION "4"
    PUBLIC_HEADER "${EV_HEADERS}"
)

install(TARGETS ev
    EXPORT libev-targets
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

install(EXPORT libev-targets
    FILE libev-targets.cmake
    NAMESPACE ev::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/libev
)

write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/libev-config-version.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY AnyNewerVersion
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/libev-config-version.cmake
    ${CMAKE_CURRENT_SOURCE_DIR}/libev-config.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/libev
)
