# Tech stack

- Swift 6.4 via swiftly (`.swift-version`), Swift 6 language mode. Minimum macOS 26 / iOS 26.
- CMake + Ninja only (presets `release`, `debug`); no SwiftPM. CF builds as a subproject and fetches SDL3, Box2D, Box3D, PhysFS into `build/<preset>/_deps`.
- swift-collections: use `BasicContainers.UniqueArray`; the stdlib `UniqueArray` needs macOS 27.

## Code intelligence

- Both presets export `compile_commands.json`. sourcekit-lsp (Swift) uses `build/release`, else `build/debug` (`.sourcekit-lsp/config.json`; first existing path wins). clangd (C) uses `build/release` only (`.clangd` accepts a single path). Configure `release` first.
- The compile database names swiftly's `swiftc`; the sourcekit-lsp reading it must be swiftly's too, not Xcode's or the Command Line Tools'.
- Serena reads `.serena/project.yml` (`swift`, then `cpp`) only at startup; reconnect the MCP server after changing it.
