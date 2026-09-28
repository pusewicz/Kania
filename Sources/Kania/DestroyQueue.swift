internal import CCute
import Synchronization

/// GPU objects whose owners have gone away, destroyed after the frame is presented.
///
/// CF's draw batch keeps the ids of what it draws until the frame is presented, so destroying an
/// object as soon as its owner goes away could free something a queued draw still uses. A `deinit`
/// can also run on any thread, so the queue is locked, and only the main thread drains it.
enum DestroyQueue {
  /// A GPU object waiting to be destroyed, by CF id.
  enum Item: Sendable {
    case canvas(UInt64)
  }

  private static let items = Mutex<[Item]>([])

  /// Destroys `item` after the current frame is presented. Safe to call from any thread.
  static func destroyAtEndOfFrame(_ item: Item) {
    items.withLock { $0.append(item) }
  }

  /// Destroys everything queued so far. Call on the main thread, after the frame is presented.
  @MainActor
  static func drain() {
    let pending = items.withLock { items in
      defer { items.removeAll() }
      return items
    }
    for item in pending {
      switch item {
      case .canvas(let id): cf_destroy_canvas(CF_Canvas(id: id))
      }
    }
  }

  /// How many objects are waiting to be destroyed.
  static var count: Int { items.withLock { $0.count } }
}

/// Internal state Kania's own tests check.
package enum Diagnostics {
  /// How many GPU objects are waiting to be destroyed at the end of the frame.
  package static var pendingDestroyCount: Int { DestroyQueue.count }
}
