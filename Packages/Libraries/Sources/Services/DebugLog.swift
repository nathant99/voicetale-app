import Foundation

/// Categorized debug emitter for VoiceTale. Single seam — every call routes
/// through ``emit(_:_:_:error:)``. `#if DEBUG`-gated, so release builds compile
/// to zero overhead. Per `@.claude/rules/debug-logging.md` § "Build a categorized
/// logger from day one".
public enum DebugLog {
    public static func lifecycle(_ message: String, _ context: StaticString = #function) {
        emit("LIFE", message, context, error: nil)
    }

    public static func startup(_ message: String, _ context: StaticString = #function) {
        emit("STARTUP", message, context, error: nil)
    }

    public static func data(_ message: String, _ context: StaticString = #function, error: Error? = nil) {
        emit("DATA", message, context, error: error)
    }

    public static func permission(_ message: String, _ context: StaticString = #function) {
        emit("PERM", message, context, error: nil)
    }

    public static func audio(_ message: String, _ context: StaticString = #function, error: Error? = nil) {
        emit("AUDIO", message, context, error: error)
    }

    public static func state(_ message: String, _ context: StaticString = #function) {
        emit("STATE", message, context, error: nil)
    }

    public static func error(_ message: String, _ context: StaticString = #function, error: Error? = nil) {
        emit("ERR", message, context, error: error)
    }

    private static func emit(_ category: String, _ message: String, _ context: StaticString, error: Error?) {
        #if DEBUG
        let thread = Thread.isMainThread ? "main" : "bg(\(Thread.current.name ?? "unnamed"))"
        if let error {
            print("[\(category)] \(context) — \(message) — error=\(error) [thread=\(thread)]")
        } else {
            print("[\(category)] \(context) — \(message) [thread=\(thread)]")
        }
        #endif
    }
}
