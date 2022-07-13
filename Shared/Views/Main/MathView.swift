//
//  MathView.swift
//  Sort Visualizer (iOS)
//
//  Created by Nicholas Hubbard on 7/7/22.
//

import SwiftUI
import WebKit

internal struct MathWebView: UIViewRepresentable {
  var text: String
  var math: String
  
  private let template = #"""
  <html>
    <head>
      <script>
        MathJax = {
          options: {
            renderActions: {
              addMenu: []
            }
          }
        };
      </script>
      <script src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-svg.js" type="text/javascript" id="MathJax-script"></script>
      <style>
        * {
          background-color: #1e1e1e !important;
          color: white !important;
          font-family: "Helvetica Neue Bold";
          font-size: 16px;
          font-weight: 400;
        }
        table, td {
          border: none;
        }
        svg {
          transform: 0, 0;
        }
        g {
          fill: white !important;
          stroke: white !important;
        }
      </style>
    </head>
    <body>
      <table>
        <tbody>
          <td><p>[text]:</p></td>
          <td><span class="math inline">[math]</span></td>
        </tbody>
      </table>
    </body>
  </html>
  """#
  
  func makeUIView(context: Context) -> WKWebView {
    let preferences = WKPreferences()
    preferences.isTextInteractionEnabled = false
    let config = WKWebViewConfiguration()
    config.preferences = preferences
    let view = WKWebView(frame: .zero, configuration: config)
    view.scrollView.isScrollEnabled = false
    return view
  }
  
  func updateUIView(_ webView: WKWebView, context: Context) {
    webView.loadHTMLString(
      template
        .replacingOccurrences(of: "[math]", with: math)
        .replacingOccurrences(of: "[text]", with: text),
      baseURL: nil
    )
  }
}

struct MathView: View {
  var text: String
  var unicode: String
  var math: String

  var body: some View {
    MathWebView(text: text, math: math)
      .accessibilityValue("\(text): \(unicode)")
  }
}

struct MathView_Previews: PreviewProvider {
  static var previews: some View {
    MathView(text: "Example", unicode: "no", math: #"\\(O(n^{\\log{3}/\\log{1.5}})\\)"#)
      .padding()
  }
}
