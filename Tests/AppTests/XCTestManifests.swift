import XCTest

extension RoutesTestCase {
    static let __allTests = [
        ("testCannotAddSameCardTwice", testCannotAddSameCardTwice),
        ("testCannotDownvoteCardAtZeroVotes", testCannotDownvoteCardAtZeroVotes),
        ("testCannotUpvoteNonExistentCard", testCannotUpvoteNonExistentCard),
        ("testEditCard", testEditCard),
        ("testNewCard", testNewCard),
        ("testResultSuccess", testResultSuccess),
        ("testUpVoteCard", testUpVoteCard),
        ("testWsOnText", testWsOnText),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(RoutesTestCase.__allTests),
    ]
}
#endif
