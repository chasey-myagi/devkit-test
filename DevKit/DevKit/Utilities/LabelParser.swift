import Foundation

enum LabelParser {
    struct ParsedLabels {
        var severity: String?
        var priority: String?
        var customer: String?
    }

    static func parse(_ labels: [String]) -> ParsedLabels {
        var result = ParsedLabels()
        for label in labels {
            if label.hasPrefix("severity/") {
                result.severity = String(label.dropFirst("severity/".count))
            } else if label.hasPrefix("priority/") {
                result.priority = String(label.dropFirst("priority/".count))
            } else if label.hasPrefix("customer/") {
                result.customer = String(label.dropFirst("customer/".count))
            }
        }
        return result
    }
}
