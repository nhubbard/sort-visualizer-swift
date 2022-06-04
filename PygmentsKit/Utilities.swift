//
//  Utilities.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 6/3/22.
//

import Foundation

// I hope these are able to be compiled successfully. Otherwise we're in for a rough time...
let splitPathRegex = try! NSRegularExpression(pattern: #"[/\\ ]"#)
fileprivate let doctypeLookupRegexPattern = #"""
<!DOCTYPE\s+(
 [a-zA-Z_][a-zA-Z0-9]*
 (?: \s+      # optional in HTML5
 [a-zA-Z_][a-zA-Z0-9]*\s+
 "[^"]*")?
 )
 [^>]*>
"""#
let doctypeLookupRegex = try! NSRegularExpression(pattern: doctypeLookupRegexPattern, options: [.dotMatchesLineSeparators, .allowCommentsAndWhitespace, .anchorsMatchLines])
let tagRegex = try! NSRegularExpression(pattern: #"<(.+?)(\s.*?)?>.*?</.+?>"#, options: [.caseInsensitive, .dotMatchesLineSeparators, .allowCommentsAndWhitespace, .anchorsMatchLines])
let xmlDeclRegex = try! NSRegularExpression(pattern: #"\s*<\?xml[^>]*\?>"#, options: [.caseInsensitive])

/// An error from Pygments. Might not end up being used.
struct ClassNotFound: Error, CustomStringConvertible {
  public var description: String = "Could not find a matching class to load."
}

/// Another error from Pygments. Might not end up being used.
struct OptionError: Error, CustomStringConvertible {
  public var description: String = "This option is invalid."
}

// We're going to try to do strongly typed options. This might not work out well, but
// at least it will be a fun experiment.

// getChoiceOpt(options: [String: Any], optionName: String, default: Any, normalCase: Bool = false) -> String
// Replace this with an enum for each choice.
// This kind of function is repeated for booleans, integers, and lists/arrays of items.

// Skipping function docstring_headline; it's very Python-specific, and I don't know
// of any way to introspect the headline of the documentation for a function in Swift.

// Skipping function make_analysator; I can't comprehend what it actually does.

/**
 * Check if the given regexp matches the last part of the shebang, if one exists.
 *
 * Examples:
 *   - `shebangMatches(shebang: "#!/usr/bin/env python", regexp: #"python(2\.\d)?"#)` returns `true`
 *   - `shebangMatches(shebang: "#!/usr/bin/python-ruby", regexp: #"python(2\.\d)?"#)` returns `false`
 *
 * It also checks for common Windows executable file extensions:
 *   - `shebangMatches(shebang: "#!C:\\Python2.4\\Python.exe", regexp: #"python(2\.\d)?"#)` returns `true`
 *
 * Parameters are ignored, so a shebang like `perl -e` is the same as `perl`.
 *
 * Note that this method automatically searches the whole string; the regexp is implicitly wrapped in `'^$'`.
 */
// TODO: I give up. This is absolute madness in Swift.
/*
func shebangMatches(shebang: String, regexp: NSRegularExpression) -> Bool {
  var index = shebang.firstIndex(of: "\n")
  var firstLine: String
  if index != nil {
    firstLine = shebang[..<index!].lowercased()
  } else {
    firstLine = shebang.lowercased()
  }
  if firstLine.starts(with: "#!") {
    var found: [String] = []
    let strippedInput = firstLine.dropFirst(2).trimmingCharacters(in: .whitespacesAndNewlines)
    for x in strippedInput.ranges(of: #"[/\\ ]"#, options: .regularExpression) {
      let xString = String(strippedInput[x])
      if !xString.starts(with: "-") {
        found.append(xString)
      }
    }
    let trueFound = found.last
    let regex = #"^%s(\.(exe|cmd|bat|bin))?$"#
  }
}*/

// TODO: This utilities file is kinda crazy. I'm going to skip writing the functions until I absolutely need them.
