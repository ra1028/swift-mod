import Foundation
import SwiftModCore
import XCTest
import Yams

func assertConfigurationCoding(_ configuration: Configuration, file: StaticString = #file, line: UInt = #line) {
    do {
        let encoded = try YAMLEncoder().encode(configuration)
        let decoded = try YAMLDecoder().decode(Configuration.self, from: encoded)

        XCTAssertEqual(configuration.format, decoded.format, file: file, line: line)
        XCTAssertEqual(configuration.targets.count, decoded.targets.count, file: file, line: line)

        for (name, target) in configuration.targets {
            guard let decodedTarget = decoded.targets[name] else {
                XCTFail("Decoded configuration has not a rule '\(name)'", file: file, line: line)
                continue
            }

            XCTAssertEqual(target.paths, decodedTarget.paths, file: file, line: line)
            XCTAssertEqual(target.excludedPaths, decodedTarget.excludedPaths, file: file, line: line)
            XCTAssertEqual(target.rules.count, decodedTarget.rules.count, file: file, line: line)
        }
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
        let configuration = Configuration(format: nil, targets: [:])
        assertConfigurationCoding(configuration)
    }

    func testTabFormatCodable() {
        let configuration = Configuration(
            format: Format(
                indent: .tab,
                lineBreakBeforeEachArgument: nil
            ),
            targets: [:]
        )
        assertConfigurationCoding(configuration)
    }
}
