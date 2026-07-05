import JavaScriptCore
import SortEngineKit

@objc protocol JSRecordingEngineExport: JSExport {
    func compare(_ i: Int, _ j: Int) -> Bool
    func swap(_ i: Int, _ j: Int)
    func getValue(_ i: Int) -> Int
    func setValue(_ i: Int, _ value: Int)
    func count() -> Int
    func markSorted(_ i: Int)
}

/// The only interface a script ever touches — mirrors `RecordingEngine`'s primitive surface
/// exactly, so native and scripted algorithms produce the same shape of `Tape` (§2.1/§2.2).
@objc final class JSRecordingEngineBridge: NSObject, JSRecordingEngineExport {
    private(set) var engine: RecordingEngine

    init(engine: RecordingEngine) {
        self.engine = engine
    }

    func compare(_ i: Int, _ j: Int) -> Bool { engine.compare(i, j) }
    func swap(_ i: Int, _ j: Int) { engine.swap(i, j) }
    func getValue(_ i: Int) -> Int { engine.values[i] }
    func setValue(_ i: Int, _ value: Int) { engine.setValue(i, value) }
    func count() -> Int { engine.count }
    func markSorted(_ i: Int) { engine.markSorted(i) }
}
