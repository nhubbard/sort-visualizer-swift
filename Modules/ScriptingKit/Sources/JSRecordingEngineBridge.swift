import JavaScriptCore
import SortEngineKit

@objc protocol JSRecordingEngineExport: JSExport {
    func compare(_ i: Int, _ j: Int) -> Bool
    func swap(_ i: Int, _ j: Int)
    func getValue(_ i: Int) -> Int
    func setValue(_ i: Int, _ value: Int)
    func count() -> Int
    func markSorted(_ i: Int)
    func mark(_ marker: Int, _ index: Int)
    func unmark(_ marker: Int)
    func unmarkAll()
    /// Returns the new aux array's handle as a raw `Int` — `AuxHandle` itself doesn't cross the
    /// JS bridge, scripts just pass the number back into `writeAux`/`deleteAuxArray`.
    func createAuxArray(_ length: Int) -> Int
    func writeAux(_ handle: Int, _ index: Int, _ value: Int)
    func deleteAuxArray(_ handle: Int)
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
    func mark(_ marker: Int, _ index: Int) { engine.mark(marker, at: index) }
    func unmark(_ marker: Int) { engine.unmark(marker) }
    func unmarkAll() { engine.unmarkAll() }
    func createAuxArray(_ length: Int) -> Int { engine.createAuxArray(length: length).rawValue }
    func writeAux(_ handle: Int, _ index: Int, _ value: Int) { engine.writeAux(AuxHandle(rawValue: handle), at: index, value: value) }
    func deleteAuxArray(_ handle: Int) { engine.deleteAuxArray(AuxHandle(rawValue: handle)) }
}
