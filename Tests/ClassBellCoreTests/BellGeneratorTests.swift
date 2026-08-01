import Foundation
import Testing
@testable import ClassBellCore

@Suite("原创铃声")
struct BellGeneratorTests {
    @Test("生成可播放的双音铃文件")
    func createsBell() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let url = directory.appendingPathComponent("bell.wav")
        try BellGenerator().createIfNeeded(at: url)
        let size = try #require(
            FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber
        )
        #expect(size.intValue > 10_000)
        try? FileManager.default.removeItem(at: directory)
    }
}
