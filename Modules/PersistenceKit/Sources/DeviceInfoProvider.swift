import Foundation
#if targetEnvironment(macCatalyst) || os(macOS)
import IOKit
#else
import DeviceKit
#endif

public struct DeviceInfo: Sendable, Equatable {
    public let model: String
}

/// Mirrors `Legacy/Shared/Data/Primary/SortViewModel.swift`'s exact branch: IOKit's
/// `IOPlatformExpertDevice` on macOS/Catalyst (DeviceKit doesn't resolve real Mac model names),
/// `DeviceKit`'s `Device.current.realDevice.safeDescription` everywhere else.
public enum DeviceInfoProvider {
    public static func current() -> DeviceInfo {
        #if targetEnvironment(macCatalyst) || os(macOS)
        var modelIdentifier: String?
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        if let modelData = IORegistryEntryCreateCFProperty(service, "model" as CFString, kCFAllocatorDefault, 0)
            .takeRetainedValue() as? Data {
            modelIdentifier = String(data: modelData, encoding: .utf8)
        }
        IOObjectRelease(service)
        return DeviceInfo(model: modelIdentifier ?? "VirtualMac1,1")
        #else
        return DeviceInfo(model: Device.current.realDevice.safeDescription)
        #endif
    }
}
