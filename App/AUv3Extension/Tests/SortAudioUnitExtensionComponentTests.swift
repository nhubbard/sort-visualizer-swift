import AudioToolbox
import SortAudioUnitKit
import XCTest

@MainActor
final class SortAudioUnitExtensionComponentTests: XCTestCase {
  private var componentDescription: AudioComponentDescription {
    func code(_ value: String) -> FourCharCode {
      value.utf8.reduce(0) { ($0 << 8) | FourCharCode($1) }
    }
    return AudioComponentDescription(
      componentType: kAudioUnitType_MusicDevice,
      componentSubType: code("SrtS"), componentManufacturer: code("NkHb"),
      componentFlags: 0, componentFlagsMask: 0)
  }

  func testParameterEditsAndHostAutomationStayInSyncAcrossReconnect() async throws {
    let unit = try SortAudioUnit(componentDescription: componentDescription)
    let model = SortAudioUnitParameterModel(audioUnit: unit)
    let gain = try XCTUnwrap(unit.parameterTree?.allParameters.first { $0.identifier == "gain" })
    let attack = try XCTUnwrap(unit.parameterTree?.allParameters.first { $0.identifier == "attack" })
    let detune = try XCTUnwrap(unit.parameterTree?.allParameters.first { $0.identifier == "detune" })

    model.setGain(0.35)
    XCTAssertEqual(model.gain, 0.35, accuracy: 0.001)
    XCTAssertEqual(Double(gain.value), 0.35, accuracy: 0.001)
    gain.setValue(0.7, originator: nil)
    try await waitForValue { abs(model.gain - 0.7) < 0.001 }

    model.disconnectObserver()
    gain.setValue(0.2, originator: nil)
    try await Task.sleep(for: .milliseconds(50))
    XCTAssertEqual(model.gain, 0.7, accuracy: 0.001)
    model.reconnectObserver()
    XCTAssertEqual(model.gain, 0.2, accuracy: 0.001)
    gain.setValue(0.8, originator: nil)
    try await waitForValue { abs(model.gain - 0.8) < 0.001 }

    model.setGain(-5)
    XCTAssertEqual(model.gain, 0)
    XCTAssertEqual(gain.value, 0)
    model.setDetune(500)
    XCTAssertEqual(model.detune, 50)
    XCTAssertEqual(detune.value, 50)
    let oldAttack = model.attack
    model.setAttack(.nan)
    XCTAssertEqual(model.attack, oldAttack)
    XCTAssertEqual(Double(attack.value), oldAttack, accuracy: 0.001)
    model.disconnectObserver()
  }

  func testControllerHostsTheParameterViewWhenAudioUnitArrivesFirst() throws {
    let controller = SortAudioUnitViewController()
    let unit = try controller.createAudioUnit(with: componentDescription)
    XCTAssertTrue(unit is SortAudioUnit)
    controller.loadViewIfNeeded()
    XCTAssertEqual(controller.children.count, 1)
    XCTAssertEqual(controller.preferredContentSize.width, 420)
    XCTAssertEqual(controller.children[0].view.superview, controller.view)
  }

  func testControllerHostsTheParameterViewWhenViewLoadsFirst() async throws {
    let controller = SortAudioUnitViewController()
    controller.loadViewIfNeeded()
    XCTAssertTrue(controller.children.isEmpty)
    _ = try controller.createAudioUnit(with: componentDescription)
    try await waitForValue { controller.children.count == 1 }
    XCTAssertEqual(controller.children[0].view.superview, controller.view)
  }

  private func waitForValue(_ predicate: () -> Bool) async throws {
    let deadline = ContinuousClock.now + .seconds(2)
    while !predicate(), ContinuousClock.now < deadline {
      try await Task.sleep(for: .milliseconds(10))
    }
    XCTAssertTrue(predicate(), "the observed AU parameter/view state did not update")
  }
}
