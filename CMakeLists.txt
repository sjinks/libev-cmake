cmake_minimum_required(VERSION 3.17)

# renovate datasource=custom.libev-attic depName=libev 
set(LIBEV_VERSION "4.31")
project(libev VERSION ${LIBEV_VERSION} LANGUAGES C)

set(CMAKE_VERBOSE_MAKEFILE ON)
set(CMAKE_CONFIGURATION_TYPES "Debug;Release;RelWithDebInfo;MinSizeRel")
if(CMAKE_GENERATOR MATCHES "Ninja Multi-Config")
    set(CMAKE_DEFAULT_BUILD_TYPE "Release")
endif()

if(POLICY CMP0135)
    cmake_policy(SET CMP0135 NEW)
endif()

option(BUILD_SHARED_LIBS "Build shared libraries" ON)

add_library(ev)
add_library(ev::ev ALIAS ev)

target_compile_definitions(ev PRIVATE $<$<CONFIG:Debug>:EV_VERIFY=3>)

include(CMakePackageConfigHelpers)
include(CheckFunctionExists)
include(CheckIncludeFiles)
include(CheckLibraryExists)
include(CheckTypeSize)
include(FetchContent)
include(GNUInstallDirs)

# AC_INCLUDES_DEFAULT (implicit)
check_include_files("sys/types.h" HAVE_SYS_TYPES_H)
check_include_files("sys/stat.h" HAVE_SYS_STAT_H)
check_include_files("stdlib.h" HAVE_STDLIB_H)
check_include_files("string.h" HAVE_STRING_H)
check_include_files("memory.h" HAVE_MEMORY_H)
check_include_files("strings.h" HAVE_STRINGS_H)
check_include_files("inttypes.h" HAVE_INTTYPES_H)
check_include_files("stdint.h" HAVE_STDINT_H)
check_include_files("unistd.h" HAVE_UNISTD_H)

# AC_HEADER_STDC (implicit)
# check_include_files("stdlib.h" HAVE_STDLIB_H)
check_include_files("stdarg.h" HAVE_STDARG_H)
# check_include_files("string.h" HAVE_STRING_H)
check_include_files("float.h" HAVE_FLOAT_H)
if(HAVE_STDLIB_H AND HAVE_STDARG_H AND HAVE_STRING_H AND HAVE_FLOAT_H)
    set(STDC_HEADERS 1)
endif()

check_include_files("dlfcn.h" HAVE_DLFCN_H)

# AC_CHECK_HEADERS(sys/inotify.h sys/epoll.h sys/event.h port.h poll.h sys/timerfd.h)
check_include_files("sys/inotify.h" HAVE_SYS_INOTIFY_H)
check_include_files("sys/epoll.h" HAVE_SYS_EPOLL_H)
check_include_files("sys/event.h" HAVE_SYS_EVENT_H)
check_include_files("port.h" HAVE_PORT_H)
check_include_files("poll.h" HAVE_POLL_H)
check_include_files("sys/timerfd.h" HAVE_SYS_TIMERFD_H)

# AC_CHECK_HEADERS(sys/select.h sys/eventfd.h sys/signalfd.h linux/aio_abi.h linux/fs.h)
check_include_files("sys/select.h" HAVE_SYS_SELECT_H)
check_include_files("sys/eventfd.h" HAVE_SYS_EVENTFD_H)
check_include_files("sys/signalfd.h" HAVE_SYS_SIGNALFD_H)
check_include_files("linux/aio_abi.h" HAVE_LINUX_AIO_ABI_H)
check_include_files("linux/fs.h" HAVE_LINUX_FS_H)

check_include_files("sys/syscall.h" HAVE_SYS_SYSCALL_H)

# AC_CHECK_FUNCS(inotify_init epoll_ctl kqueue port_create poll select eventfd signalfd)
check_function_exists(inotify_init HAVE_INOTIFY_INIT)
check_function_exists(epoll_ctl HAVE_EPOLL_CTL)
check_function_exists(kqueue HAVE_KQUEUE)
check_function_exists(port_create HAVE_PORT_CREATE)
check_function_exists(poll HAVE_POLL)
check_function_exists(select HAVE_SELECT)
check_function_exists(eventfd HAVE_EVENTFD)
check_function_exists(signalfd HAVE_SIGNALFD)

# AC_CHECK_FUNCS(clock_gettime...)
check_function_exists(clock_gettime HAVE_CLOCK_GETTIME)
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
check_function_exists(nanosleep HAVE_NANOSLEEP)
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
check_function_exists(floor HAVE_FLOOR)
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

FetchContent_Declare(ev_ext URL "http://dist.schmorp.de/libev/Attic/libev-${LIBEV_VERSION}.tar.gz" URL_HASH SHA256=ed855d2b52118e32c0c1a6a32bd18c97f9e6711ca511f5ee12de3b9eccc66e5a)
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
