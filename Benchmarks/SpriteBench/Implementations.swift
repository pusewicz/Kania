import CCute

// MARK: Raw C import

/// The C benchmark's entity layout, imported types only.
struct RawEntity {
  var sprite: CF_Sprite
  var velocity: CF_V2
}

/// The raw C import over manually allocated memory: the closest Swift gets to the C loop, and
/// the floor the overlay is measured against.
final class RawBufferWorkload: Workload {
  private let entities: UnsafeMutableBufferPointer<RawEntity>

  var checksum: Double {
    entities.reduce(0) { $0 + Double($1.sprite.transform.p.x) + Double($1.sprite.transform.p.y) }
  }

  /// Allocates and initialises `count` entities in the order the C benchmark does.
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

  /// Moves, animates and draws every sprite through raw pointers.
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

// MARK: Kania's shape

/// A 2D vector in the shape a Kania API might use.
typealias Vec2 = SIMD2<Float>

extension Vec2 {
  /// Converts CF's vector type.
  init(_ v: CF_V2) { self.init(v.x, v.y) }
  /// The vector as CF's type.
  var cf: CF_V2 { CF_V2(x: x, y: y) }
}

/// A value-type sprite wrapper: computed properties and methods over the C struct.
struct Sprite {
  private var raw: CF_Sprite

  /// Wraps a sprite created by CF.
  init(_ raw: CF_Sprite) { self.raw = raw }

  /// The sprite's translation, stored in its CF transform.
  var position: Vec2 {
    get { Vec2(raw.transform.p) }
    set { raw.transform.p = newValue.cf }
  }

  /// Advances the animation by the app's frame delta.
  mutating func update() { cf_sprite_update(&raw) }

  /// Queues the sprite, handing CF this value's own storage rather than a copy. `mutating` only so
  /// the pointer is to this value in place; CF reads the sprite and does not change it.
  mutating func draw() { cf_draw_sprite(&raw) }
}

/// A game entity written in plain Swift over the value-type wrapper.
struct Entity {
  var sprite: Sprite
  var velocity: Vec2

  /// Moves one fixed step, bounces off `bounds` (half extents) and advances the animation.
  mutating func step(bounds: Vec2) {
    let p = sprite.position + velocity * fixedDelta
    if abs(p.x) > bounds.x { velocity.x = -velocity.x }
    if abs(p.y) > bounds.y { velocity.y = -velocity.y }
    sprite.position = p
    sprite.update()
  }
}

/// The shape Kania ships: value-type entities in an `Array` held by a class, iterated through
/// one `MutableSpan` with unchecked element reads, since every index comes from the span's own
/// `indices`, and each sprite handed to CF in place. `PHASE1.md` records how it compares with C.
final class OverlaySpanInPlaceWorkload: Workload {
  private var entities: [Entity] = []
  private let bounds = Vec2(width / 2, height / 2)

  var checksum: Double {
    entities.reduce(0) { $0 + Double($1.sprite.position.x) + Double($1.sprite.position.y) }
  }

  /// Creates `count` entities in the order the C benchmark does.
  init(count: Int) {
    entities.reserveCapacity(count)
    makeEntities(count: count) { sprite, position, velocity in
      var s = Sprite(sprite)
      s.position = Vec2(position)
      entities.append(Entity(sprite: s, velocity: Vec2(velocity)))
    }
  }

  /// Steps and draws every entity through one mutable span, unchecked and in place.
  func step(frame: Int) {
    var span = entities.mutableSpan
    for i in span.indices {
      unsafe span[unchecked: i].step(bounds: bounds)
      unsafe span[unchecked: i].sprite.draw()
    }
  }
}
