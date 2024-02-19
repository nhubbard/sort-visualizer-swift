//
//  SortArrayAction.swift
//  Sort Symphony (iOS)
//
//  Created by Nicholas Hubbard on 2/19/24.
//

import Foundation
import SwiftUI

public enum SortArrayAction {
  case setData([SortItem])
  case swap(Int, Int)
  case compare(Int, Int)
  case setValue(Int, Int)
  case setItem(Int, SortItem)
  case changeColor(Int, Color)
  case resetColor(Int)
}
