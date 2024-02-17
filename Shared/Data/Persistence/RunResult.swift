//
//  RunResult.swift
//  Sort Symphony (iOS)
//
//  Created by Nicholas Hubbard on 5/17/23.
//

import Foundation
import CloudKit

struct RunRecord: CustomCloudKitCodable, Sendable {
  /// The system fields used by CloudKit
  var cloudKitSystemFields: Data?
  /// The system model, such as "MacBookPro18,1"
  var systemModel: String
  /// The Unix epoch that this record was created on
  var created: Int
  /// The algorithm this record is for
  var algorithmName: String
  /// The number of items sorted
  var arraySize: Int
  /// The number of operations completed
  var operations: Int
  /// The amount of time needed to sort the array
  var elapsedTime: Double
  /// The number of operations per second
  var pace: Double
  /// The delay for this entry
  var delay: Float
}
