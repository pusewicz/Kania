internal import CCute

/// An error from Kania, with a message that says what failed.
public struct KaniaError: Error, CustomStringConvertible {
  /// What failed.
  public let description: String

  /// Creates an error that says what failed.
  public init(_ description: String) {
    self.description = description
  }

  /// Creates an error from a failed Cute Framework result.
  init(_ result: CF_Result) {
    self.description = result.details.map { String(cString: $0) } ?? "Cute Framework error \(result.code)"
  }
}
