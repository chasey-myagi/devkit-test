import Foundation

/// 单个文件的 diff 信息
struct FileDiff: Identifiable, Sendable {
    let id = UUID()
    var oldPath: String
    var newPath: String
    var hunks: [DiffHunk]
    var isNewFile: Bool
    var isDeleted: Bool
    var isBinary: Bool

    var additions: Int { hunks.flatMap(\.lines).filter { $0.type == .addition }.count }
    var deletions: Int { hunks.flatMap(\.lines).filter { $0.type == .deletion }.count }
}

/// diff 中的一个 hunk 段
struct DiffHunk: Identifiable, Sendable {
    let id = UUID()
    var header: String          // @@ -1,5 +1,7 @@
    var oldStart: Int
    var newStart: Int
    var lines: [DiffLine]
}

/// diff 中的一行
struct DiffLine: Identifiable, Sendable {
    let id = UUID()
    var type: LineType
    var content: String
    var oldLineNumber: Int?
    var newLineNumber: Int?

    enum LineType: Sendable {
        case context
        case addition
        case deletion
    }
}
