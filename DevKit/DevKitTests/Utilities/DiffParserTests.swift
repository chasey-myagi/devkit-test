import Testing
import Foundation
@testable import DevKit

@Suite("DiffParser")
struct DiffParserTests {

    @Test func parseSimpleDiff() {
        let raw = """
        diff --git a/file.swift b/file.swift
        --- a/file.swift
        +++ b/file.swift
        @@ -1,3 +1,4 @@
         line1
        +added
         line2
         line3
        """
        let files = DiffParser.parse(raw)
        #expect(files.count == 1)
        #expect(files[0].newPath == "file.swift")
        #expect(files[0].oldPath == "file.swift")
        #expect(files[0].additions == 1)
        #expect(files[0].deletions == 0)
        #expect(files[0].hunks.count == 1)
        #expect(files[0].hunks[0].lines.count == 4)
        #expect(files[0].isNewFile == false)
        #expect(files[0].isDeleted == false)
        #expect(files[0].isBinary == false)
    }

    @Test func parseNewFile() {
        let raw = """
        diff --git a/new.swift b/new.swift
        new file mode 100644
        --- /dev/null
        +++ b/new.swift
        @@ -0,0 +1,3 @@
        +line1
        +line2
        +line3
        """
        let files = DiffParser.parse(raw)
        #expect(files.count == 1)
        #expect(files[0].isNewFile == true)
        #expect(files[0].isDeleted == false)
        #expect(files[0].additions == 3)
        #expect(files[0].deletions == 0)
    }

    @Test func parseDeletedFile() {
        let raw = """
        diff --git a/old.swift b/old.swift
        deleted file mode 100644
        --- a/old.swift
        +++ /dev/null
        @@ -1,2 +0,0 @@
        -line1
        -line2
        """
        let files = DiffParser.parse(raw)
        #expect(files.count == 1)
        #expect(files[0].isDeleted == true)
        #expect(files[0].isNewFile == false)
        #expect(files[0].additions == 0)
        #expect(files[0].deletions == 2)
    }

    @Test func parseBinaryFile() {
        let raw = """
        diff --git a/image.png b/image.png
        Binary files a/image.png and b/image.png differ
        """
        let files = DiffParser.parse(raw)
        #expect(files.count == 1)
        #expect(files[0].isBinary == true)
        #expect(files[0].hunks.isEmpty)
    }

    @Test func parseMultipleFiles() {
        let raw = """
        diff --git a/file1.swift b/file1.swift
        --- a/file1.swift
        +++ b/file1.swift
        @@ -1,2 +1,3 @@
         line1
        +added
         line2
        diff --git a/file2.swift b/file2.swift
        --- a/file2.swift
        +++ b/file2.swift
        @@ -1,3 +1,2 @@
         line1
        -removed
         line3
        """
        let files = DiffParser.parse(raw)
        #expect(files.count == 2)
        #expect(files[0].newPath == "file1.swift")
        #expect(files[0].additions == 1)
        #expect(files[0].deletions == 0)
        #expect(files[1].newPath == "file2.swift")
        #expect(files[1].additions == 0)
        #expect(files[1].deletions == 1)
    }

    @Test func parseMultipleHunks() {
        let raw = """
        diff --git a/file.swift b/file.swift
        --- a/file.swift
        +++ b/file.swift
        @@ -1,3 +1,4 @@
         line1
        +added1
         line2
         line3
        @@ -10,3 +11,4 @@
         line10
        +added2
         line11
         line12
        """
        let files = DiffParser.parse(raw)
        #expect(files.count == 1)
        #expect(files[0].hunks.count == 2)
        #expect(files[0].hunks[0].oldStart == 1)
        #expect(files[0].hunks[0].newStart == 1)
        #expect(files[0].hunks[1].oldStart == 10)
        #expect(files[0].hunks[1].newStart == 11)
        #expect(files[0].additions == 2)
    }

    @Test func parseEmptyInput() {
        let files = DiffParser.parse("")
        #expect(files.isEmpty)
    }

    @Test func lineNumbersAreCorrect() {
        let raw = """
        diff --git a/file.swift b/file.swift
        --- a/file.swift
        +++ b/file.swift
        @@ -1,3 +1,4 @@
         context
        +added
        -removed
         context2
        """
        let files = DiffParser.parse(raw)
        #expect(files.count == 1)
        let lines = files[0].hunks[0].lines
        #expect(lines.count == 4)

        // context: old=1, new=1
        #expect(lines[0].type == .context)
        #expect(lines[0].oldLineNumber == 1)
        #expect(lines[0].newLineNumber == 1)

        // addition: old=nil, new=2
        #expect(lines[1].type == .addition)
        #expect(lines[1].oldLineNumber == nil)
        #expect(lines[1].newLineNumber == 2)

        // deletion: old=2, new=nil
        #expect(lines[2].type == .deletion)
        #expect(lines[2].oldLineNumber == 2)
        #expect(lines[2].newLineNumber == nil)

        // context2: old=3, new=3
        #expect(lines[3].type == .context)
        #expect(lines[3].oldLineNumber == 3)
        #expect(lines[3].newLineNumber == 3)
    }

    @Test func parseDiffWithModification() {
        let raw = """
        diff --git a/file.swift b/file.swift
        --- a/file.swift
        +++ b/file.swift
        @@ -5,3 +5,3 @@
         unchanged
        -old line
        +new line
         unchanged
        """
        let files = DiffParser.parse(raw)
        #expect(files.count == 1)
        #expect(files[0].additions == 1)
        #expect(files[0].deletions == 1)
        #expect(files[0].hunks[0].oldStart == 5)
        #expect(files[0].hunks[0].newStart == 5)
    }
}
