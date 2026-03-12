import Testing
@testable import DevKit

@Suite("LabelParser")
struct LabelParserTests {
    @Test func extractsSeverity() {
        let labels = ["kind/bug", "severity/s0", "customer/中芯国际"]
        let parsed = LabelParser.parse(labels)
        #expect(parsed.severity == "s0")
    }

    @Test func extractsPriority() {
        let labels = ["kind/bug", "priority/p0"]
        let parsed = LabelParser.parse(labels)
        #expect(parsed.priority == "p0")
    }

    @Test func extractsCustomer() {
        let labels = ["kind/bug-moi", "customer/安利"]
        let parsed = LabelParser.parse(labels)
        #expect(parsed.customer == "安利")
    }

    @Test func handlesNoMatchingLabels() {
        let labels = ["kind/bug", "kind/bug-moi"]
        let parsed = LabelParser.parse(labels)
        #expect(parsed.severity == nil)
        #expect(parsed.priority == nil)
        #expect(parsed.customer == nil)
    }

    @Test func handlesEmptyLabels() {
        let parsed = LabelParser.parse([])
        #expect(parsed.severity == nil)
        #expect(parsed.priority == nil)
        #expect(parsed.customer == nil)
    }
}
