/// Resource ceilings the decoder enforces before trusting a frame's own declared sizes. Sized
/// comfortably above any real archive this app ships but low enough to reject a corrupted or
/// hostile declaration before it drives an allocation.
public struct ZstdDecodingLimits: Sendable, Equatable {
  public var maximumOutputSize: Int
  public var maximumWindowSize: Int
  public var maximumDictionarySize: Int
  public var maximumBlockCount: Int
  public var maximumFrameSize: Int

  public init(
    maximumOutputSize: Int = 1 << 30,
    maximumWindowSize: Int = 1 << 27,
    maximumDictionarySize: Int = 1 << 25,
    maximumBlockCount: Int = 1 << 20,
    maximumFrameSize: Int = 1 << 30
  ) {
    self.maximumOutputSize = maximumOutputSize
    self.maximumWindowSize = maximumWindowSize
    self.maximumDictionarySize = maximumDictionarySize
    self.maximumBlockCount = maximumBlockCount
    self.maximumFrameSize = maximumFrameSize
  }

  public static let `default` = ZstdDecodingLimits()
}
