internal import CCute

/// A colour with red, green, blue and alpha components from 0 to 1.
public struct Color: Hashable, Sendable {
  /// The red component, from 0 to 1.
  public var red: Float

  /// The green component, from 0 to 1.
  public var green: Float

  /// The blue component, from 0 to 1.
  public var blue: Float

  /// The alpha component, from 0 (transparent) to 1 (opaque).
  public var alpha: Float

  /// Creates a colour from its components, each from 0 to 1.
  public init(red: Float, green: Float, blue: Float, alpha: Float = 1) {
    self.red = red
    self.green = green
    self.blue = blue
    self.alpha = alpha
  }

  /// The colour as CF's type.
  var cf: CF_Color { CF_Color(r: red, g: green, b: blue, a: alpha) }
}

/// A pixel read back from the GPU, with 8-bit red, green, blue and alpha components.
public struct Pixel: Hashable, Sendable {
  /// The red component, from 0 to 255.
  public var red: UInt8

  /// The green component, from 0 to 255.
  public var green: UInt8

  /// The blue component, from 0 to 255.
  public var blue: UInt8

  /// The alpha component, from 0 (transparent) to 255 (opaque).
  public var alpha: UInt8

  /// Creates a pixel from its components, each from 0 to 255.
  public init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
    self.red = red
    self.green = green
    self.blue = blue
    self.alpha = alpha
  }
}
