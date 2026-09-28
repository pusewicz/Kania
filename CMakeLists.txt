cmake_minimum_required(VERSION 4.2)

# A game that pulls Kania in chooses these itself; Kania sets them only when built on its own.
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
  set(CMAKE_OSX_DEPLOYMENT_TARGET 26.0 CACHE STRING "Minimum macOS version")
  # Swift on Windows links against the MSVC runtime, so CF and its C libraries are built with MSVC.
  if(CMAKE_HOST_WIN32 AND NOT DEFINED CMAKE_C_COMPILER)
    set(CMAKE_C_COMPILER cl)
    set(CMAKE_CXX_COMPILER cl)
  endif()
endif()

project(Kania LANGUAGES C CXX Swift)

option(KANIA_BUILD_SAMPLES "Build the samples and benchmarks" ${PROJECT_IS_TOP_LEVEL})
option(KANIA_BUILD_TESTS "Build the tests" ${PROJECT_IS_TOP_LEVEL})
option(KANIA_INDEX_STORE "Write the Swift index store that sourcekit-lsp reads" ${PROJECT_IS_TOP_LEVEL})

set(CMAKE_C_STANDARD 23)
# CMake gives C the macOS deployment target but not Swift, which then targets the build machine's
# own OS version.
if(APPLE AND CMAKE_OSX_DEPLOYMENT_TARGET AND NOT CMAKE_Swift_COMPILER_TARGET)
  set(CMAKE_Swift_COMPILER_TARGET "${CMAKE_SYSTEM_PROCESSOR}-apple-macosx${CMAKE_OSX_DEPLOYMENT_TARGET}")
endif()
set(CMAKE_Swift_LANGUAGE_VERSION 6)
set(CMAKE_Swift_COMPILATION_MODE "$<IF:$<CONFIG:Debug>,incremental,wholemodule>")
set(CMAKE_Swift_MODULE_DIRECTORY ${PROJECT_BINARY_DIR}/swift)
# sourcekit-lsp does not index a compile-database project itself; it reads the store the build writes.
if(KANIA_INDEX_STORE)
  add_compile_options("$<$<COMPILE_LANGUAGE:Swift>:-index-store-path;${PROJECT_BINARY_DIR}/index/store>")
endif()
# Swift has no debug C runtime on Windows, so every configuration uses the release DLL runtime.
set(CMAKE_MSVC_RUNTIME_LIBRARY MultiThreadedDLL)
if(PROJECT_IS_TOP_LEVEL)
  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/bin)
endif()

# On Linux, SDL3 and s2n (CF's TLS library, through FindThreads) link with -pthread, which swiftc
# rejects. Swift links hand it to clang, swiftc's linker driver, instead.
set(kania_pthread_link_option "$<IF:$<LINK_LANGUAGE:Swift>,SHELL:-Xclang-linker -pthread,-pthread>")
# FindThreads leaves an existing Threads::Threads alone, so creating it first lets Kania adjust it.
if(UNIX AND NOT APPLE AND NOT TARGET Threads::Threads)
  set(THREADS_PREFER_PTHREAD_FLAG ON)
  find_package(Threads REQUIRED)
  set_target_properties(Threads::Threads PROPERTIES
    INTERFACE_LINK_LIBRARIES ""
    INTERFACE_LINK_OPTIONS "${kania_pthread_link_option}")
endif()

# Cute Framework, pinned in the submodule. It fetches SDL3, Box2D, Box3D and PhysFS itself.
set(CF_FRAMEWORK_STATIC ON)
set(CF_CUTE_SHADERC OFF)
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)
add_subdirectory(Vendor/cute_framework EXCLUDE_FROM_ALL)

if(TARGET SDL3-static)
  get_target_property(sdl_link_options SDL3-static INTERFACE_LINK_OPTIONS)
  if(sdl_link_options)
    list(TRANSFORM sdl_link_options REPLACE "^-pthread$" "${kania_pthread_link_option}")
    set_property(TARGET SDL3-static PROPERTY INTERFACE_LINK_OPTIONS "${sdl_link_options}")
  endif()
endif()

# The C shim Swift imports CF through; see Sources/CCute/include/CCute.h.
add_library(CCute STATIC Sources/CCute/CCute.c)
target_include_directories(CCute PUBLIC Sources/CCute/include)
target_link_libraries(CCute PUBLIC cute)

add_library(Kania STATIC
  Sources/Kania/App.swift
  Sources/Kania/Canvas.swift
  Sources/Kania/Color.swift
  Sources/Kania/DestroyQueue.swift
  Sources/Kania/Draw.swift
  Sources/Kania/Game.swift
  Sources/Kania/Kania.swift
  Sources/Kania/KaniaError.swift
  Sources/Kania/Readback.swift
  Sources/Kania/Sprite.swift)
# Kania's tests share its package, so they can check its `package` diagnostics.
target_compile_options(Kania PRIVATE "SHELL:-package-name Kania")
target_include_directories(Kania INTERFACE ${CMAKE_Swift_MODULE_DIRECTORY})
# Public: Kania's types will hold CF values, so clients need CCute to lay them out.
target_link_libraries(Kania PUBLIC CCute)
# Kania drains libdispatch's main queue itself on Linux and Windows; see CCute.h.
target_link_libraries(Kania PUBLIC $<$<OR:$<PLATFORM_ID:Linux>,$<PLATFORM_ID:Windows>>:dispatch>)

if(KANIA_BUILD_TESTS)
  enable_testing()
  add_executable(AppLoopTest Tests/AppLoop/AppLoopTest.swift)
  target_compile_options(AppLoopTest PRIVATE -parse-as-library)
  target_link_libraries(AppLoopTest PRIVATE Kania)
  add_test(NAME app-loop COMMAND AppLoopTest)

  add_executable(CanvasTest Tests/Canvas/CanvasTest.swift)
  target_compile_options(CanvasTest PRIVATE -parse-as-library "SHELL:-package-name Kania")
  target_link_libraries(CanvasTest PRIVATE Kania)
  add_test(NAME canvas COMMAND CanvasTest)

  add_executable(SpriteTest Tests/Sprites/SpriteTest.swift)
  target_compile_options(SpriteTest PRIVATE -parse-as-library)
  target_link_libraries(SpriteTest PRIVATE Kania)
  add_test(NAME sprites COMMAND SpriteTest)

  # A game that never quits would otherwise hold CI for ctest's default 25 minutes.
  set_tests_properties(app-loop canvas sprites PROPERTIES TIMEOUT 60)
endif()

if(KANIA_BUILD_SAMPLES)
  add_library(SpikeSupport STATIC Sources/SpikeSupport/Support.swift)
  target_include_directories(SpikeSupport INTERFACE ${CMAKE_Swift_MODULE_DIRECTORY})
  target_link_libraries(SpikeSupport PUBLIC CCute)

  add_executable(HelloTriangle Samples/HelloTriangle/main.swift)
  target_link_libraries(HelloTriangle PRIVATE SpikeSupport)

  add_executable(SpriteBench
    Benchmarks/SpriteBench/main.swift
    Benchmarks/SpriteBench/Implementations.swift
    Benchmarks/SpriteBench/Workload.swift)
  target_link_libraries(SpriteBench PRIVATE SpikeSupport)

  add_executable(SpriteBenchC Benchmarks/SpriteBenchC/main.c)
  target_link_libraries(SpriteBenchC PRIVATE CCute)
  # CMake's Release level for C is already -O3, matching CF's. Swift never fuses a * b + c into
  # an FMA and clang does by default; turn that off so both benchmarks' checksums agree bit for bit.
  target_compile_options(SpriteBenchC PRIVATE $<$<NOT:$<C_COMPILER_ID:MSVC>>:-ffp-contract=off>)
endif()
