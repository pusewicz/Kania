// Checks sprite drawing through a readback: a sprite drawn alone lands where its position says,
// with y pointing up, two sprites drawn as a batch both land where theirs say, and nothing is drawn
// anywhere else. The readback's rows run from the top of the canvas. Exits with status 0 when all
// hold, and 1 with the reason when one does not.
import CCute
import Kania

@main
struct SpriteTest: Game, ~Copyable {
  static let width = 320
  static let height = 240
  static var window: WindowOptions { WindowOptions(title: "SpriteTest", width: width, height: height) }

  private var canvas: Canvas
  private var single: Sprite
  private var batch: [Sprite]
  private var readback: Readback?
  private var frame = 0

  init() throws(KaniaError) {
    canvas = try Canvas(width: Self.width, height: Self.height)
    single = Sprite.demo()
    single.position = [0, 60]
    single.scale = [2, 2]
    batch = [Sprite.demo(), Sprite.demo()]
    batch[0].position = [-100, -60]
    batch[1].position = [100, -60]
    for index in batch.indices { batch[index].scale = [2, 2] }
  }

  mutating func update() {
    if frame > 0 { check() }
    frame += 1
  }

  mutating func draw() {
    guard frame == 1 else { return }
    Draw.sprite(single)
    Draw.sprites(&batch)
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
    let boxes = ([single] + batch).map { box(around: $0) }
    for (name, box) in zip(["the single sprite", "batch sprite 0", "batch sprite 1"], boxes)
    where !box.contains(where: { pixels[$0].alpha > 0 }) {
      fail("\(name) drew nothing inside rows \(box.rows), columns \(box.columns)")
    }
    let stray = pixels.indices.first { index in
      pixels[index].alpha > 0 && !boxes.contains { $0.contains(index) }
    }
    if let stray {
      fail("pixel at row \(stray / Self.width), column \(stray % Self.width) was drawn outside every sprite")
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
  cfs_host_print_error("SpriteTest: \(reason)\n")
  exit(1)
}
