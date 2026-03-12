import Foundation
import SwiftData

@Model
final class Workspace {
    var name: String
    var repoFullName: String
    var localPath: String
    var pollingIntervalSeconds: Int
    var maxConcurrency: Int
    var isActive: Bool

    init(
        name: String,
        repoFullName: String,
        localPath: String,
        pollingIntervalSeconds: Int = 1800,
        maxConcurrency: Int = 2,
        isActive: Bool = false
    ) {
        self.name = name
        self.repoFullName = repoFullName
        self.localPath = localPath
        self.pollingIntervalSeconds = pollingIntervalSeconds
        self.maxConcurrency = maxConcurrency
        self.isActive = isActive
    }
}
