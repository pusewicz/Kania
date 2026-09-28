internal import CCute

/// An animated sprite: frames from an Aseprite file, with its own position, scale, opacity and
/// playback state.
///
/// A sprite is a value, so copies move and animate independently. The frame images are shared, and
/// stay loaded in CF's sprite cache.
public struct Sprite {
  /// CF's sprite.
  var raw: CF_Sprite

  /// CF's built-in demo sprite: a girl, with the animations "idle", "up", "side", "hold_down",
  /// "hold_side" and "hold_up".
  ///
  /// Loading it creates GPU textures, so call it once the game is running, from ``Game/init()`` on.
  @MainActor
  public static func demo() -> Sprite {
    Sprite(raw: cf_make_demo_sprite())
  }

  /// Wraps a sprite CF made.
  init(raw: CF_Sprite) {
    self.raw = raw
  }

  /// Loads a sprite from an Aseprite file.
  ///
  /// CF caches loaded files, so loading the same path again is cheap, and the images stay loaded.
  /// Loading creates GPU textures, so call it once the game is running, from ``Game/init()`` on.
  ///
  /// Before CF parses the file, Kania checks its header: the magic number, and that the file is as
  /// long as the header says. That catches files that are not Aseprite files and truncated files.
  /// A file with a well-formed header but corrupt contents can still crash CF, whose parser does not
  /// validate in release builds. That stays so until Kania has its own Aseprite loader.
  ///
  /// - Parameter path: A virtual path in the ``FileSystem``, such as "/images/girl.aseprite".
  /// - Throws: ``KaniaError`` if the file is missing, is not an Aseprite file or is truncated.
  @MainActor
  public init(contentsOf path: String) throws(KaniaError) {
    try Self.checkAsepriteHeader(atPath: path)
    var loaded = cf_sprite_defaults()
    let result = cf_sprite_load(path, &loaded)
    if cf_is_error(result) {
      throw KaniaError("could not load the sprite \"\(path)\": \(KaniaError(result))")
    }
    raw = loaded
  }

  /// The length of an Aseprite file's header in bytes.
  private static let asepriteHeaderLength = 128

  /// The magic number at offset 4 of an Aseprite file.
  private static let asepriteMagic: UInt16 = 0xA5E0

  /// Reads the start of an Aseprite file through the virtual file system, and throws if the file
  /// is missing, is too short for a header, lacks the magic number, or is shorter than the size its
  /// header declares.
  @MainActor
  private static func checkAsepriteHeader(atPath path: String) throws(KaniaError) {
    var stat = CF_Stat()
    let statResult = cf_fs_stat(path, &stat)
    if cf_is_error(statResult) {
      throw KaniaError("could not load the sprite \"\(path)\": \(KaniaError(statResult))")
    }
    let size = Int(stat.size)
    guard size >= asepriteHeaderLength else {
      throw KaniaError(
        "could not load the sprite \"\(path)\": it is not an Aseprite file, it has \(size) bytes and a header needs \(asepriteHeaderLength)"
      )
    }

    guard let file = cf_fs_open_file_for_read(path) else {
      throw KaniaError("could not load the sprite \"\(path)\": it could not be opened")
    }
    var start = [UInt8](repeating: 0, count: 6)
    let count = start.withUnsafeMutableBytes { cf_fs_read(file, $0.baseAddress, $0.count) }
    _ = cf_fs_close(file)
    guard count == start.count else {
      throw KaniaError("could not load the sprite \"\(path)\": its header could not be read")
    }

    let declaredSize = Int(start[0]) | Int(start[1]) << 8 | Int(start[2]) << 16 | Int(start[3]) << 24
    let magic = UInt16(start[4]) | UInt16(start[5]) << 8
    guard magic == asepriteMagic else {
      throw KaniaError("could not load the sprite \"\(path)\": it is not an Aseprite file")
    }
    guard declaredSize == size else {
      throw KaniaError(
        "could not load the sprite \"\(path)\": it is truncated or corrupt, its header says \(declaredSize) bytes and the file has \(size)"
      )
    }
  }

  /// Where the sprite is drawn. The origin is the centre of the window, x points right and y up,
  /// and one unit is one point.
  public var position: SIMD2<Float> {
    get { SIMD2(raw.transform.p.x, raw.transform.p.y) }
    set { raw.transform.p = CF_V2(x: newValue.x, y: newValue.y) }
  }

  /// How much the sprite is stretched along x and y. At (1, 1) it is drawn at its original size.
  public var scale: SIMD2<Float> {
    get { SIMD2(raw.scale.x, raw.scale.y) }
    set { raw.scale = CF_V2(x: newValue.x, y: newValue.y) }
  }

  /// How opaque the sprite is drawn, from 0 (invisible) to 1 (fully opaque).
  public var opacity: Float {
    get { raw.opacity }
    set { raw.opacity = newValue }
  }

  /// The width of one frame in pixels, before scaling.
  public var width: Int { Int(raw.w) }

  /// The height of one frame in pixels, before scaling.
  public var height: Int { Int(raw.h) }

  /// Starts playing `animation` from its first frame.
  @MainActor
  public mutating func play(_ animation: String) {
    cf_sprite_play(&raw, animation)
  }

  /// Advances the animation by the time the last frame took.
  @MainActor
  public mutating func update() {
    cf_sprite_update(&raw)
  }

  /// Queues the sprite, handing CF this value's own storage rather than a copy. `mutating` only so
  /// the pointer is to this value in place; CF reads the sprite and does not change it.
  @MainActor
  mutating func draw() {
    cf_draw_sprite(&raw)
  }
}
