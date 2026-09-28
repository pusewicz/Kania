// swift-tools-version: 6.2
import PackageDescription

// Phase 0 spike: Swift over a prebuilt, static Cute Framework (CF).
// Run `Scripts/build-cf.sh` once per triple before `swift build`.
//
// The unsafeFlags below make this package unusable as a remote SwiftPM dependency.
// That is acceptable for the spike; packaging for games is a Phase 1 decision.

func defaultTriple() -> String {
  #if os(macOS)
    #if arch(arm64)
      return "arm64-apple-macosx"
    #else
      return "x86_64-apple-macosx"
    #endif
  #elseif os(Linux)
    #if arch(arm64)
      return "aarch64-unknown-linux-gnu"
    #else
      return "x86_64-unknown-linux-gnu"
    #endif
  #elseif os(Windows)
    return "x86_64-unknown-windows-msvc"
  #else
    return "unknown"
  #endif
}

let triple = Context.environment["KANIA_TRIPLE"] ?? defaultTriple()
let prebuilt = "\(Context.packageDirectory)/Vendor/prebuilt/\(triple)"

// Mirrors Vendor/prebuilt/<triple>/link.txt, which build-cf.sh harvests from CMake.
let macFrameworks = [
  "IOKit", "Foundation", "Security", "QuartzCore", "Metal", "MetalKit", "Network", "VideoToolbox",
  "CoreMedia", "CoreVideo", "CoreFoundation", "Cocoa", "ForceFeedback", "Carbon", "CoreAudio",
  "AudioToolbox", "AVFoundation", "GameController",
]
let macWeakFrameworks = ["UniformTypeIdentifiers", "CoreHaptics"]
let windowsLibraries = [
  "crypt32", "mfplat", "mfreadwrite", "mfuuid", "ole32", "ws2_32", "shlwapi", "d3d11", "d3d12",
  "dxgi", "dxguid", "user32", "gdi32", "winmm", "imm32", "version", "setupapi", "advapi32",
  "shell32", "oleaut32", "uuid",
]

var cfLinkerSettings: [LinkerSetting] = [
  .unsafeFlags(["-L\(prebuilt)/lib"]),
  .linkedLibrary("cute"),
  .linkedLibrary("SDL3"),
  .linkedLibrary("physfs"),
  .linkedLibrary("SDL_uclibc", .when(platforms: [.macOS, .linux])),
  .linkedLibrary("c++", .when(platforms: [.macOS])),
  .linkedLibrary("stdc++", .when(platforms: [.linux])),
  .linkedLibrary("m", .when(platforms: [.macOS, .linux])),
  .linkedLibrary("pthread", .when(platforms: [.macOS, .linux])),
  .linkedLibrary("GL", .when(platforms: [.linux])),
  .linkedLibrary("dl", .when(platforms: [.linux])),
]
cfLinkerSettings += windowsLibraries.map { .linkedLibrary($0, .when(platforms: [.windows])) }
cfLinkerSettings += macFrameworks.map { .linkedFramework($0, .when(platforms: [.macOS])) }
cfLinkerSettings += macWeakFrameworks.map {
  .unsafeFlags(["-Xlinker", "-weak_framework", "-Xlinker", $0], .when(platforms: [.macOS]))
}

// Extra Swift flags for the benchmark only, e.g. "-enforce-exclusivity=unchecked" or "-Ounchecked".
// Build such variants with their own --scratch-path.
let benchSwiftFlags = (Context.environment["KANIA_BENCH_SWIFTFLAGS"] ?? "")
  .split(separator: " ").map(String.init)

let cfHeaders: [CSetting] = [.unsafeFlags(["-I\(prebuilt)/include"])]
let cfHeadersForSwift: [SwiftSetting] = [.unsafeFlags(["-Xcc", "-I\(prebuilt)/include"])]

let package = Package(
  name: "Kania",
  platforms: [.macOS(.v26), .iOS(.v26)],
  targets: [
    .target(
      name: "CCute",
      path: "Sources/CCute",
      cSettings: cfHeaders,
      linkerSettings: cfLinkerSettings),
    .target(
      name: "SpikeSupport",
      dependencies: ["CCute"],
      path: "Sources/SpikeSupport",
      swiftSettings: cfHeadersForSwift),
    .executableTarget(
      name: "HelloTriangle",
      dependencies: ["CCute", "SpikeSupport"],
      path: "Samples/HelloTriangle",
      swiftSettings: cfHeadersForSwift),
    .executableTarget(
      name: "SpriteBench",
      dependencies: ["CCute", "SpikeSupport"],
      path: "Benchmarks/SpriteBench",
      swiftSettings: cfHeadersForSwift + (benchSwiftFlags.isEmpty ? [] : [.unsafeFlags(benchSwiftFlags)])),
    .executableTarget(
      name: "SpriteBenchC",
      dependencies: ["CCute"],
      path: "Benchmarks/SpriteBenchC",
      // -O3 matches CF's CMake Release build; SwiftPM's release default for C is -Os.
      // Swift never fuses a * b + c into an FMA; clang does by default. Match Swift so the
      // position checksums of both benchmarks agree bit for bit.
      cSettings: cfHeaders + [.unsafeFlags(["-O3", "-ffp-contract=off"])]),
  ]
)
