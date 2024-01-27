get_filename_component(LIBEV_CMAKE_DIR "${CMAKE_CURRENT_LIST_FILE}" PATH)

list(APPEND CMAKE_MODULE_PATH ${LIBEV_CMAKE_DIR})

if(NOT TARGET ev::ev)
    include("${LIBEV_CMAKE_DIR}/libev-targets.cmake")
endif()

set(EV_LIBRARIES ev::ev)
