// Checks loading files through the virtual file system: the base directory is mounted at the root,
// a directory mounts under a mount point and unmounts again, a sprite loaded from a file draws
// inside its box and nowhere else, and a missing, non-Aseprite or truncated file is an error, not a
// modal dialog that blocks the game or a crash. The content directory is the first argument.
// Exits with status 0 when all hold, and 1 with the reason when one does not.
import CCute
import Kania

@main
struct AssetTest: Game, ~Copyable {
  static let width = 320
  static let height = 240
  static var window: WindowOptions { WindowOptions(title: "AssetTest", width: width, height: height) }

  #if os(Windows)
    private static let executable = "/AssetTest.exe"
  #else
    private static let executable = "/AssetTest"
  #endif

  private var canvas: Canvas
  private var sprite: Sprite
  private var contentDirectory: String
  private var readback: Readback?
  private var frame = 0

  init() throws(KaniaError) {
    canvas = try Canvas(width: Self.width, height: Self.height)
    guard CommandLine.arguments.count > 1 else { fail("usage: AssetTest <content directory>") }
    contentDirectory = CommandLine.arguments[1]
    Self.checkFileSystem(contentDirectory: contentDirectory)
    sprite = Self.loadSprite()
    Self.checkBrokenSpritesThrow()
  }

  /// Loads the girl from the mounted content directory, placed at the origin and scaled by 2.
  private static func loadSprite() -> Sprite {
    do {
      var sprite = try Sprite(contentsOf: "/test/girl.aseprite")
      if sprite.width <= 0 || sprite.height <= 0 {
        fail("the loaded sprite is \(sprite.width) by \(sprite.height) pixels")
      }
      sprite.position = [0, 0]
      sprite.scale = [2, 2]
      return sprite
    } catch {
      fail("could not load /test/girl.aseprite: \(error)")
    }
  }

  /// Checks the base directory and mounts the content directory at "/test".
  private static func checkFileSystem(contentDirectory: String) {
    if FileSystem.baseDirectory.isEmpty { fail("the base directory is empty") }
    if !FileSystem.fileExists(atPath: executable) {
      fail("\(executable) is not in the virtual file system, so the base directory is not mounted")
    }
    do {
      try FileSystem.mount(contentDirectory, at: "/test")
    } catch {
      fail("could not mount the content directory: \(error)")
    }
    if !FileSystem.fileExists(atPath: "/test/girl.aseprite") {
      fail("/test/girl.aseprite does not exist after mounting \(contentDirectory)")
    }
    if FileSystem.fileExists(atPath: "/test/missing.aseprite") { fail("/test/missing.aseprite exists") }
    do {
      try FileSystem.mount(contentDirectory + "/no-such-directory", at: "/nowhere")
      fail("a directory that does not exist was mounted")
    } catch {}
  }

  /// Checks that files that cannot be loaded as sprites are errors whose message names the path and
  /// says why. CF shows a modal dialog for a missing file in `cf_make_sprite`, and its parser crashes
  /// on a file that is not an Aseprite file, so either would end the test by timeout or crash.
  private static func checkBrokenSpritesThrow() {
    let cases = [
      ("missing", "not found"),
      ("not-aseprite", "not an Aseprite file"),
      ("truncated", "truncated"),
    ]
    for (name, reason) in cases {
      let path = "/test/\(name).aseprite"
      do {
        _ = try Sprite(contentsOf: path)
        fail("\(path) loaded as a sprite")
      } catch {
        if !error.description.contains(path) { fail("the error for \(path) does not name it: \(error)") }
        if !error.description.contains(reason) {
          fail("the error for \(path) does not say \"\(reason)\": \(error)")
        }
      }
    }
  }

  mutating func update() {
    if frame > 0 { check() }
    frame += 1
  }

  mutating func draw() {
    guard frame == 1 else { return }
    Draw.sprite(sprite)
    Draw.render(to: canvas)
    readback = canvas.readPixels()
  }

  private func check() {
    guard let readback else { return }
    if let error = readback.error { fail("the readback failed: \(error)") }
    guard let pixels = readback.pixels else {
      if frame > 60 { fail("the readback had not finished by frame 60") }
      return
    }
    let box = box(around: sprite)
    if !box.contains(where: { pixels[$0].alpha > 0 }) {
      fail("the sprite drew nothing inside rows \(box.rows), columns \(box.columns)")
    }
    if let stray = pixels.indices.first(where: { pixels[$0].alpha > 0 && !box.contains($0) }) {
      fail("pixel at row \(stray / Self.width), column \(stray % Self.width) was drawn outside the sprite")
    }

    do {
      try FileSystem.unmount(contentDirectory)
    } catch {
      fail("could not unmount the content directory: \(error)")
    }
    if FileSystem.fileExists(atPath: "/test/girl.aseprite") {
      fail("/test/girl.aseprite still exists after unmounting \(contentDirectory)")
    }
    App.quit()
  }

  /// The pixels a sprite may cover, with a margin for its pivot, assuming rows run from the top of
  /// the canvas and y points up.
  private func box(around sprite: Sprite) -> PixelBox {
    let halfWidth = Int(Float(sprite.width) * sprite.scale.x) / 2 + 4
    let halfHeight = Int(Float(sprite.height) * sprite.scale.y) / 2 + 4
    let column = Self.width / 2 + Int(sprite.position.x)
    let row = Self.height / 2 - Int(sprite.position.y)
    return PixelBox(
      rows: (row - halfHeight)...(row + halfHeight), columns: (column - halfWidth)...(column + halfWidth),
      width: Self.width)
  }
}

/// A rectangle of pixels in a readback.
struct PixelBox {
  let rows: ClosedRange<Int>
  let columns: ClosedRange<Int>
  let width: Int

  /// Whether the pixel at `index` in a readback lies inside the box.
  func contains(_ index: Int) -> Bool {
    rows.contains(index / width) && columns.contains(index % width)
  }

  /// Whether any pixel inside the box satisfies `predicate`, given its index in the readback.
  func contains(where predicate: (Int) -> Bool) -> Bool {
    rows.contains { row in columns.contains { predicate(row * width + $0) } }
  }
}

/// Prints why the test failed and exits with status 1.
func fail(_ reason: String) -> Never {
  cfs_host_print_error("AssetTest: \(reason)\n")
  exit(1)
}
