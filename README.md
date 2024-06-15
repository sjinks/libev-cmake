# libev-cmake

[![Build](https://github.com/sjinks/libev-cmake/actions/workflows/build.yml/badge.svg)](https://github.com/sjinks/libev-cmake/actions/workflows/build.yml)

libev with CMake support.

## Usage with [FetchContent](https://cmake.org/cmake/help/latest/module/FetchContent.html)

```cmake
include(FetchContent)
FetchContent_Declare(ev GIT_REPOSITORY https://github.com/sjinks/libev-cmake GIT_TAG v4.33)
FetchContent_MakeAvailable(ev)

target_link_libraries(mytarget ev::ev)
```

## Usage with [CPM.cmake](https://github.com/cpm-cmake/CPM.cmake)

```cmake
file(DOWNLOAD https://github.com/cpm-cmake/CPM.cmake/releases/download/v0.40.0/CPM.cmake ${CMAKE_CURRENT_BINARY_DIR}/cmake/CPM.cmake)
include(${CMAKE_CURRENT_BINARY_DIR}/cmake/CPM.cmake)

CPMAddPackage("gh:sjinks/libev-cmake@4.33")
```
