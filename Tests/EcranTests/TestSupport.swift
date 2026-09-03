import Domain
import Foundation
import Infrastructure
import WindowGeometry
@testable import EcranCore

@MainActor
final class TestHarness {
    private(set) var failed = 0
    private(set) var passed = 0

    func expect(
        _ condition: @autoclosure () -> Bool,
        _ message: String,
        file: String = #fileID,
        line: Int = #line
    ) {
        if condition() {
            passed += 1
        } else {
            failed += 1
            FileHandle.standardError.write(Data("FAIL \(file):\(line) \(message)\n".utf8))
        }
    }

    func expectEqual<T: Equatable & Sendable>(
        _ got: T,
        _ want: T,
        _ message: String,
        file: String = #fileID,
        line: Int = #line
    ) {
        expect(got == want, "\(message) (got \(got), want \(want))", file: file, line: line)
    }

    func finish() -> Int {
        if failed == 0 {
            FileHandle.standardOutput.write(Data("EcranSelfTests: \(passed) passed\n".utf8))
        } else {
            FileHandle.standardError.write(Data("EcranSelfTests: \(failed) failed, \(passed) passed\n".utf8))
        }
        return failed == 0 ? 0 : 1
    }
}

struct IsolatedBox {
    let directory: URL
    let store: JSONSettingsStore

    static func make() -> IsolatedBox {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ecran-tests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let store = JSONSettingsStore(fileURL: directory.appendingPathComponent("settings.json"))
        return IsolatedBox(directory: directory, store: store)
    }

    func tearDown() {
        try? FileManager.default.removeItem(at: directory)
    }
}
