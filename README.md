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
file(DOWNLOAD https://github.com/cpm-cmake/CPM.cmake/releases/download/v0.38.3/CPM.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/cmake/CPM.cmake
    EXPECTED_HASH SHA256=cc155ce02e7945e7b8967ddfaff0b050e958a723ef7aad3766d368940cb15494
)
include(${CMAKE_CURRENT_BINARY_DIR}/cmake/CPM.cmake)

CPMAddPackage("gh:sjinks/libev-cmake@4.33")
```
