# The smallest game project that uses Kania, set up the way a game outside this repository would.
# To build against a local checkout instead of GitHub, configure with
# -DFETCHCONTENT_SOURCE_DIR_KANIA=/path/to/Kania.
cmake_minimum_required(VERSION 4.2)

set(CMAKE_OSX_DEPLOYMENT_TARGET 26.0 CACHE STRING "Minimum macOS version")
# Swift on Windows links against the MSVC runtime, so C and C++ must be built with MSVC.
if(CMAKE_HOST_WIN32 AND NOT DEFINED CMAKE_C_COMPILER)
  set(CMAKE_C_COMPILER cl)
  set(CMAKE_CXX_COMPILER cl)
endif()

project(MinimalGame LANGUAGES C CXX Swift)

set(CMAKE_Swift_LANGUAGE_VERSION 6)
if(APPLE)
  set(CMAKE_Swift_COMPILER_TARGET "${CMAKE_SYSTEM_PROCESSOR}-apple-macosx${CMAKE_OSX_DEPLOYMENT_TARGET}")
endif()
set(CMAKE_MSVC_RUNTIME_LIBRARY MultiThreadedDLL)

include(FetchContent)
FetchContent_Declare(Kania
  GIT_REPOSITORY https://github.com/pusewicz/Kania
  GIT_TAG main)
FetchContent_MakeAvailable(Kania)

add_executable(MinimalGame MinimalGame.swift)
# A one-file executable is compiled as top-level code unless told otherwise, which @main rejects.
target_compile_options(MinimalGame PRIVATE -parse-as-library)
target_link_libraries(MinimalGame PRIVATE Kania)

# Kania mounts the executable's directory at "/", so content copied next to it loads as "/content/...".
add_custom_command(TARGET MinimalGame POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_directory
    ${CMAKE_CURRENT_SOURCE_DIR}/content $<TARGET_FILE_DIR:MinimalGame>/content)
