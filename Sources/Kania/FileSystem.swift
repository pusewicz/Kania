internal import CCute

/// The game's virtual file system.
///
/// Files are found by virtual paths such as "/images/tree.aseprite", not by the paths of the
/// operating system. Directories and archives are mounted into the virtual file system, and their
/// files appear under the mount point. When the app starts, CF mounts the ``baseDirectory`` at "/".
///
/// These functions work once the game is running, from ``Game/init()`` on.
@MainActor
public enum FileSystem {
  /// The operating system's path of the directory the game runs from, which CF mounts at "/" when
  /// the app starts. It is not a virtual path, and it may differ from the working directory. The
  /// path ends with a directory separator, for example "/Users/me/Game/bin/".
  public static var baseDirectory: String {
    String(cString: cf_fs_get_base_directory())
  }

  /// Makes the files of a directory or archive available under `mountPoint`.
  ///
  /// The mount is appended, so files in earlier mounts are found before files with the same virtual
  /// path in later ones. Mounting the same path again is ignored.
  ///
  /// - Parameters:
  ///   - path: The operating system's path of a directory or archive.
  ///   - mountPoint: The virtual directory the files appear in. The default is the root.
  /// - Throws: ``KaniaError`` if `path` cannot be mounted, for example because it does not exist.
  public static func mount(_ path: String, at mountPoint: String = "/") throws(KaniaError) {
    let result = cf_fs_mount(path, mountPoint, true)
    if cf_is_error(result) {
      throw KaniaError("could not mount \"\(path)\" at \"\(mountPoint)\": \(KaniaError(result))")
    }
  }

  /// Removes a directory or archive from the virtual file system, so its files are no longer found.
  ///
  /// - Parameter path: The operating system's path given to ``mount(_:at:)``.
  /// - Throws: ``KaniaError`` if `path` is not mounted.
  public static func unmount(_ path: String) throws(KaniaError) {
    let result = cf_fs_dismount(path)
    if cf_is_error(result) {
      throw KaniaError("could not unmount \"\(path)\": \(KaniaError(result))")
    }
  }

  /// Whether a file exists at a virtual path.
  public static func fileExists(atPath path: String) -> Bool {
    cf_fs_file_exists(path)
  }
}
