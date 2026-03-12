import Foundation
import os

private let logger = Logger(subsystem: "com.chasey.DevKit", category: "AttachmentDownloader")

@MainActor
final class AttachmentDownloader {
    private let processRunner: ProcessRunning

    init(processRunner: ProcessRunning = ProcessRunner()) {
        self.processRunner = processRunner
    }

    struct AttachmentResult: Sendable {
        var url: String
        var localPath: String?  // nil if failed
        var error: String?
    }

    /// 下载附件到指定目录
    /// 目录结构: {localPath}/issues/{issueNumber}/{filename}
    func downloadAttachments(urls: [String], localPath: String, issueNumber: Int) async -> [AttachmentResult] {
        let directory = "\(localPath)/issues/\(issueNumber)"

        // 创建目录
        do {
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        } catch {
            logger.error("Failed to create directory \(directory): \(error.localizedDescription)")
            return urls.map { AttachmentResult(url: $0, localPath: nil, error: "Failed to create directory: \(error.localizedDescription)") }
        }

        var results: [AttachmentResult] = []

        for url in urls {
            let filename = URL(string: url)?.lastPathComponent ?? "attachment"
            let destPath = "\(directory)/\(filename)"

            do {
                _ = try await processRunner.run("curl", arguments: [
                    "-L", "-o", destPath, url
                ])
                logger.info("Downloaded \(url) to \(destPath)")
                results.append(AttachmentResult(url: url, localPath: destPath, error: nil))
            } catch {
                logger.error("Failed to download \(url): \(error.localizedDescription)")
                results.append(AttachmentResult(url: url, localPath: nil, error: error.localizedDescription))
            }
        }

        return results
    }
}
