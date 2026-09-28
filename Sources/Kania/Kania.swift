internal import CCute

/// The version of the Cute Framework build Kania links, as CF reports it.
public func cuteFrameworkVersion() -> String {
  String(cString: cf_version_string_linked())
}
