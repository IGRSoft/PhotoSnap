import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(PhotoSnapTests.allTests),
        testCase(PhotoSnapConfigurationTest.allTests),
    ]
}
#endif
