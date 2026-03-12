import Foundation

/// 解析 unified diff 格式（`gh pr diff` 输出）为结构化模型
enum DiffParser {
    /// 解析完整的 diff 输出为 FileDiff 数组
    static func parse(_ raw: String) -> [FileDiff] {
        guard !raw.isEmpty else { return [] }

        // 按 "diff --git " 分割各文件段
        let parts = raw.components(separatedBy: "diff --git ")
        return parts.dropFirst().compactMap { parseFileSection($0) }
    }

    // MARK: - Private

    private static func parseFileSection(_ section: String) -> FileDiff? {
        let lines = section.components(separatedBy: "\n")
        guard let firstLine = lines.first else { return nil }

        // 从 "a/path b/path" 提取文件路径
        let (oldPath, newPath) = extractPaths(from: firstLine)

        var isNewFile = false
        var isDeleted = false
        var isBinary = false
        var hunks: [DiffHunk] = []

        // 扫描头部元信息
        var lineIdx = 1
        while lineIdx < lines.count {
            let line = lines[lineIdx]
            if line.hasPrefix("new file mode") {
                isNewFile = true
            } else if line.hasPrefix("deleted file mode") {
                isDeleted = true
            } else if line.contains("Binary files") || line.contains("GIT binary patch") {
                isBinary = true
            } else if line.hasPrefix("@@ ") {
                // 开始解析 hunks
                break
            } else if line.hasPrefix("--- ") || line.hasPrefix("+++ ") {
                // 跳过文件路径行
            }
            lineIdx += 1
        }

        // 解析所有 hunks
        while lineIdx < lines.count {
            let line = lines[lineIdx]
            if line.hasPrefix("@@ ") {
                // 收集当前 hunk 的所有行
                let header = line
                var hunkLines: [String] = []
                lineIdx += 1
                while lineIdx < lines.count && !lines[lineIdx].hasPrefix("@@ ") {
                    hunkLines.append(lines[lineIdx])
                    lineIdx += 1
                }
                if let hunk = parseHunk(header: header, lines: hunkLines) {
                    hunks.append(hunk)
                }
            } else {
                lineIdx += 1
            }
        }

        return FileDiff(
            oldPath: oldPath,
            newPath: newPath,
            hunks: hunks,
            isNewFile: isNewFile,
            isDeleted: isDeleted,
            isBinary: isBinary
        )
    }

    /// 从 "a/path b/path" 格式提取新旧路径
    private static func extractPaths(from line: String) -> (old: String, new: String) {
        // 格式: "a/some/path b/some/path"
        let parts = line.split(separator: " ", maxSplits: 1)
        let oldPath: String
        let newPath: String

        if parts.count == 2 {
            oldPath = String(parts[0]).hasPrefix("a/")
                ? String(String(parts[0]).dropFirst(2))
                : String(parts[0])
            newPath = String(parts[1]).hasPrefix("b/")
                ? String(String(parts[1]).dropFirst(2))
                : String(parts[1])
        } else {
            oldPath = String(line)
            newPath = String(line)
        }

        return (oldPath, newPath)
    }

    /// 解析 @@ 头部和内容行为 DiffHunk
    private static func parseHunk(header: String, lines: [String]) -> DiffHunk? {
        let (oldStart, newStart) = parseHunkHeader(header)

        var diffLines: [DiffLine] = []
        var oldLine = oldStart
        var newLine = newStart

        for line in lines {
            if line.isEmpty {
                // 空行当作 context 行
                diffLines.append(DiffLine(
                    type: .context,
                    content: "",
                    oldLineNumber: oldLine,
                    newLineNumber: newLine
                ))
                oldLine += 1
                newLine += 1
                continue
            }

            let prefix = line.first
            let content = String(line.dropFirst())

            switch prefix {
            case "+":
                diffLines.append(DiffLine(
                    type: .addition,
                    content: content,
                    oldLineNumber: nil,
                    newLineNumber: newLine
                ))
                newLine += 1
            case "-":
                diffLines.append(DiffLine(
                    type: .deletion,
                    content: content,
                    oldLineNumber: oldLine,
                    newLineNumber: nil
                ))
                oldLine += 1
            case " ":
                diffLines.append(DiffLine(
                    type: .context,
                    content: content,
                    oldLineNumber: oldLine,
                    newLineNumber: newLine
                ))
                oldLine += 1
                newLine += 1
            case "\\":
                // "\ No newline at end of file" - 跳过
                break
            default:
                // 未知前缀，当作 context
                diffLines.append(DiffLine(
                    type: .context,
                    content: line,
                    oldLineNumber: oldLine,
                    newLineNumber: newLine
                ))
                oldLine += 1
                newLine += 1
            }
        }

        return DiffHunk(
            header: header,
            oldStart: oldStart,
            newStart: newStart,
            lines: diffLines
        )
    }

    /// 从 "@@ -oldStart,oldCount +newStart,newCount @@" 提取起始行号
    private static func parseHunkHeader(_ header: String) -> (oldStart: Int, newStart: Int) {
        // 格式: @@ -1,3 +1,4 @@ 可选上下文信息
        let pattern = #"@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: header, range: NSRange(header.startIndex..., in: header)) else {
            return (1, 1)
        }

        let oldStart = Range(match.range(at: 1), in: header).flatMap { Int(header[$0]) } ?? 1
        let newStart = Range(match.range(at: 2), in: header).flatMap { Int(header[$0]) } ?? 1

        return (oldStart, newStart)
    }
}
