import Foundation
import SwiftModCore
import XCTest
import Yams

func assertConfigurationCoding(_ configuration: Configuration, file: StaticString = #filePath, line: UInt = #line) {
    do {
        let encoded = try YAMLEncoder().encode(configuration)
        let decoded = try YAMLDecoder().decode(Configuration.self, from: encoded)

        XCTAssertEqual(configuration.format, decoded.format, file: file, line: line)
        XCTAssertEqual(configuration.rules.count, decoded.rules.count, file: file, line: line)
    }
    catch {
        XCTFail("\(error)", file: file, line: line)
    }
}

final class ConfigurationCodableTests: XCTestCase {
    func testTemplateCodable() throws {
        assertConfigurationCoding(.template)
    }

    func testNilFormatCodable() {
        let configuration = Configuration(format: nil, rules: [])
        assertConfigurationCoding(configuration)
    }

    func testTabFormatCodable() {
        let configuration = Configuration(
            format: Format(
                indent: .tab,
                lineBreakBeforeEachArgument: nil
            ),
            rules: []
        )
        assertConfigurationCoding(configuration)
    }
}
