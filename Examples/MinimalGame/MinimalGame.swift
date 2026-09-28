// The smallest Kania game: CF's demo sprite, animated in the middle of the window.
import Kania

@main
struct MinimalGame: Game {
  private var sprite = Sprite.demo()

  init() {
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
