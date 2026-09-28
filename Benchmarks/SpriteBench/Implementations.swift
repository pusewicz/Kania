import CCute

// MARK: Raw C import

/// The C benchmark's entity layout, imported types only.
struct RawEntity {
  var sprite: CF_Sprite
  var velocity: CF_V2
}

/// Swift calling the imported C API directly on a Swift `Array`, the way a game written
/// against raw CF from Swift would.
final class RawArrayWorkload: Workload {
  private var entities: [RawEntity] = []

  var checksum: Double {
    entities.reduce(0) { $0 + Double($1.sprite.transform.p.x) + Double($1.sprite.transform.p.y) }
  }

  init(count: Int) {
    entities.reserveCapacity(count)
    makeEntities(count: count) { sprite, position, velocity in
      var sprite = sprite
      sprite.transform.p = position
      entities.append(RawEntity(sprite: sprite, velocity: velocity))
    }
  }

  func step(frame: Int) {
    for i in entities.indices {
      let p = cf_add_v2(entities[i].sprite.transform.p, cf_mul_v2_f(entities[i].velocity, fixedDelta))
      if p.x < -width / 2 || p.x > width / 2 { entities[i].velocity.x = -entities[i].velocity.x }
      if p.y < -height / 2 || p.y > height / 2 { entities[i].velocity.y = -entities[i].velocity.y }
      entities[i].sprite.transform.p = p
      cf_sprite_update(&entities[i].sprite)
      cf_draw_sprite(&entities[i].sprite)
    }
  }
}

/// The raw C import over manually allocated memory: the closest Swift gets to the C loop.
final class RawBufferWorkload: Workload {
  private let entities: UnsafeMutableBufferPointer<RawEntity>

  var checksum: Double {
    entities.reduce(0) { $0 + Double($1.sprite.transform.p.x) + Double($1.sprite.transform.p.y) }
  }

  init(count: Int) {
    entities = .allocate(capacity: count)
    var i = 0
    makeEntities(count: count) { sprite, position, velocity in
      var sprite = sprite
      sprite.transform.p = position
      (entities.baseAddress! + i).initialize(to: RawEntity(sprite: sprite, velocity: velocity))
      i += 1
    }
  }

  deinit {
    entities.deinitialize()
    entities.deallocate()
  }

  func step(frame: Int) {
    for i in entities.indices {
      let e = entities.baseAddress! + i
      let p = cf_add_v2(e.pointee.sprite.transform.p, cf_mul_v2_f(e.pointee.velocity, fixedDelta))
      if p.x < -width / 2 || p.x > width / 2 { e.pointee.velocity.x = -e.pointee.velocity.x }
      if p.y < -height / 2 || p.y > height / 2 { e.pointee.velocity.y = -e.pointee.velocity.y }
      e.pointee.sprite.transform.p = p
      cf_sprite_update(&e.pointee.sprite)
      cf_draw_sprite(&e.pointee.sprite)
    }
  }
}

// MARK: Idiomatic overlay prototypes

/// A 2D vector in the shape a Kania API might use.
typealias Vec2 = SIMD2<Float>

extension Vec2 {
  init(_ v: CF_V2) { self.init(v.x, v.y) }
  var cf: CF_V2 { CF_V2(x: x, y: y) }
}

/// A value-type sprite wrapper: computed properties and methods over the C struct.
struct Sprite {
  private var raw: CF_Sprite

  init(_ raw: CF_Sprite) { self.raw = raw }

  var position: Vec2 {
    get { Vec2(raw.transform.p) }
    set { raw.transform.p = newValue.cf }
  }

  mutating func play(_ animation: String) { cf_sprite_play(&raw, animation) }

  mutating func update() { cf_sprite_update(&raw) }

  func draw() {
    withUnsafePointer(to: raw) { cf_draw_sprite($0) }
  }
}

/// A game entity written in plain Swift over the value-type wrapper.
struct Entity {
  var sprite: Sprite
  var velocity: Vec2

  mutating func step(bounds: Vec2) {
    let p = sprite.position + velocity * fixedDelta
    if abs(p.x) > bounds.x { velocity.x = -velocity.x }
    if abs(p.y) > bounds.y { velocity.y = -velocity.y }
    sprite.position = p
    sprite.update()
  }
}

/// Idiomatic Swift: an `Array` of structs held by a class, stepped through methods.
final class OverlayStructWorkload: Workload {
  private var entities: [Entity] = []
  private let bounds = Vec2(width / 2, height / 2)

  var checksum: Double {
    entities.reduce(0) { $0 + Double($1.sprite.position.x) + Double($1.sprite.position.y) }
  }

  init(count: Int) {
    entities.reserveCapacity(count)
    makeEntities(count: count) { sprite, position, velocity in
      var s = Sprite(sprite)
      s.position = Vec2(position)
      entities.append(Entity(sprite: s, velocity: Vec2(velocity)))
    }
  }

  func step(frame: Int) {
    for i in entities.indices {
      entities[i].step(bounds: bounds)
      entities[i].sprite.draw()
    }
  }
}

/// The value-type overlay iterated through a `MutableSpan`: one exclusive access to the array
/// for the whole loop instead of one per element, with bounds checks kept.
@available(macOS 26, iOS 26, *)
final class OverlaySpanWorkload: Workload {
  private var entities: [Entity] = []
  private let bounds = Vec2(width / 2, height / 2)

  var checksum: Double {
    entities.reduce(0) { $0 + Double($1.sprite.position.x) + Double($1.sprite.position.y) }
  }

  init(count: Int) {
    entities.reserveCapacity(count)
    makeEntities(count: count) { sprite, position, velocity in
      var s = Sprite(sprite)
      s.position = Vec2(position)
      entities.append(Entity(sprite: s, velocity: Vec2(velocity)))
    }
  }

  func step(frame: Int) {
    var span = entities.mutableSpan
    for i in span.indices {
      span[i].step(bounds: bounds)
      span[i].sprite.draw()
    }
  }
}

/// A reference-type sprite node, the shape a scene-graph style API would take.
final class SpriteNode {
  var sprite: Sprite
  var velocity: Vec2

  init(sprite: Sprite, velocity: Vec2) {
    self.sprite = sprite
    self.velocity = velocity
  }

  func step(bounds: Vec2) {
    let p = sprite.position + velocity * fixedDelta
    if abs(p.x) > bounds.x { velocity.x = -velocity.x }
    if abs(p.y) > bounds.y { velocity.y = -velocity.y }
    sprite.position = p
    sprite.update()
  }
}

/// Idiomatic Swift with classes: an `Array` of nodes, so every iteration retains and releases.
final class OverlayClassWorkload: Workload {
  private var nodes: [SpriteNode] = []
  private let bounds = Vec2(width / 2, height / 2)

  var checksum: Double {
    nodes.reduce(0) { $0 + Double($1.sprite.position.x) + Double($1.sprite.position.y) }
  }

  init(count: Int) {
    nodes.reserveCapacity(count)
    makeEntities(count: count) { sprite, position, velocity in
      var s = Sprite(sprite)
      s.position = Vec2(position)
      nodes.append(SpriteNode(sprite: s, velocity: Vec2(velocity)))
    }
  }

  func step(frame: Int) {
    for node in nodes {
      node.step(bounds: bounds)
      node.sprite.draw()
    }
  }
}

// MARK: Text

/// Per-frame labels built with string interpolation and passed to C as `const char*`.
final class TextWorkload: Workload {
  private let count: Int

  var checksum: Double { 0 }

  init(count: Int) { self.count = count }

  func step(frame: Int) {
    let columns = 16
    for i in 0..<count {
      let x = -width / 2 + 8 + Float(i % columns) * (width / Float(columns))
      let y = height / 2 - 16 - Float((i / columns) % 44) * 16
      cf_draw_text("Entity \(i) hp \((frame + i) % 100)", CF_V2(x: x, y: y), -1)
    }
  }
}
