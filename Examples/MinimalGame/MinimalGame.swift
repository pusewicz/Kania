// The smallest Kania game: a sprite shipped next to the game, animated in the middle of the window.
import Kania

@main
struct MinimalGame: Game {
  private var sprite: Sprite

  init() throws(KaniaError) {
    sprite = try Sprite(contentsOf: "/content/girl.aseprite")
    sprite.scale = [4, 4]
    sprite.play("idle")
  }

  mutating func update() {
    sprite.update()
  }

  mutating func draw() {
    Draw.sprite(sprite)
  }
}
