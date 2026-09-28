# Conventions

- Swift idioms are defined in `.claude/agents/swift-writer.md` § "How Kania's Swift is written" (C access via CCute, explicit `@MainActor`, `throws(KaniaError)`, `~Copyable` handles with `DestroyQueue` + `ID`, `package` test hooks, draw-path shape, doc comments, British spelling). Follow that file; don't restate it here.
- API decisions and their measurements: `PHASE1.md` § Decisions.
- Formatting: `.swift-format` (2 spaces, 110 columns, ordered imports); lint is strict.
- Swift code is written by the `swift-writer` subagent; don't pass `model` when invoking it.
