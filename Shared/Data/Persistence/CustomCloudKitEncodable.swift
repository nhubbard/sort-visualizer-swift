//
//  CustomCloudKitEncodable.swift
//  Sort Visualizer (iOS)
//
//  Created by Nicholas Hubbard on 5/18/23.
//

import Foundation
import CloudKit

internal let _CKSystemFieldsKeyName = "cloudKitSystemFields"
internal let _CKIdentifierKeyName = "cloudKitIdentifier"

public protocol CloudKitRecordRepresentable {
  var cloudKitSystemFields: Data? { get }
  var cloudKitRecordType: String { get }
  var cloudKitIdentifier: String { get }
}

extension CloudKitRecordRepresentable {
  public var cloudKitRecordType: String {
    return String(describing: type(of: self))
  }

  public var cloudKitIdentifier: String {
    return UUID().uuidString
  }
}

public protocol CustomCloudKitEncodable: CloudKitRecordRepresentable & Encodable {}
public protocol CustomCloudKitDecodable: CloudKitRecordRepresentable & Decodable {}
public protocol CustomCloudKitCodable: CustomCloudKitEncodable & CustomCloudKitDecodable {}
