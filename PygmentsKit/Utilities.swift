//
//  Utilities.swift
//  PygmentsKit
//
//  Created by Nicholas Hubbard on 6/3/22.
//

import Foundation

/**
 * Given a Unicode character code with a length greater than 16 bits, return the two 16 bit surrogate pair.
 * See example D28 on http://www.unicode.org/book/ch03.pdf for more information.
 * Returns (-1, -1) if the conversion from `Character` to `Int` fails.
 */
func surrogatePair(_ c: Character) -> (Int, Int) {
  let cc = Int(String(c))
  guard cc != nil else {
    return (-1, -1)
  }
  return (0xd7c0 + (cc! >> 10), 0xdc00 + (cc! & 0x3ff))
}

/**
 * Format a sequence of strings for output.
 */
func formatLines(varName: String, seq: [String], raw: Bool = false, indentLevel: Int = 0) -> String {
  var lines: [String] = []
  let baseIndent = String(repeating: " ", count: indentLevel * 4)
  let innerIndent = String(repeating: " ", count: (indentLevel + 1) * 4)
  lines.append("\(baseIndent)\(innerIndent) = (")
  if raw {
    // These should be preformatted reprs of, say, tuples.
    for i in seq {
      lines.append("\(innerIndent)\(i),")
    }
  } else {
    for i in seq {
      // Force use of single quotes.
      // This part is untested; I can't find the equivalent of the Python repr function.
      let r = "'\(i)'\""
      let lastTwo = r.index(r.endIndex, offsetBy: -2)..<r.endIndex
      lines.append(innerIndent + r[lastTwo] + String(r.last!) + ",")
    }
  }
  lines.append(baseIndent + ")")
  return lines.joined(separator: "\n")
}

/**
 * Returns a list with duplicates removed from the iterable `it`.
 * Order is preserved.
 */
func duplicatesRemoved<T>(_ it: [T], alreadySeen: [T] = []) -> [T] where T : Equatable {
  var output: [T] = []
  var seen: [T] = []
  for i in it {
    if seen.contains(i) {
      continue
    } else if alreadySeen.contains(i) {
      continue
    }
    output.append(i)
    seen.append(i)
  }
  return output
}
