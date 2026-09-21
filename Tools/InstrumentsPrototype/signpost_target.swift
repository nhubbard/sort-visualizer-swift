import Darwin
import Dispatch
import os

// Let an attaching recorder finish preflight before emitting the interval.
usleep(1_500_000)
// Construct after preflight because the logging system caches whether a
// subsystem is dynamically enabled when the signposter is initialized.
let signposter = OSSignposter(
    logger: Logger(subsystem: "com.nhubbard.InstrumentsPrototype", category: "PointsOfInterest"))
let identifier = signposter.makeSignpostID()
let state = signposter.beginInterval("Prototype interval", id: identifier, "fixture")
signposter.emitEvent("Prototype event", id: identifier, "fixture")
let deadline = DispatchTime.now().uptimeNanoseconds + 1_000_000_000
var accumulator: UInt64 = 0
while DispatchTime.now().uptimeNanoseconds < deadline {
  accumulator &+= 1
}
signposter.emitEvent("Prototype checksum", id: identifier, "\(accumulator)")
signposter.endInterval("Prototype interval", state)
// Allow the unified logging pipeline to deliver its final records.
usleep(500_000)
