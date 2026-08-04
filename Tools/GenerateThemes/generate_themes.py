#!/usr/bin/env python3
"""Regenerates `Modules/DesignSystemKit/Sources/Themes/*.swift` from real Pygments style data.

Separate from `App/Resources/AlgorithmDetails/manage.py` on purpose — that pipeline is scoped to
per-algorithm content, not app styling. Run via `uv run generate_themes.py`.

Approach: treat this as a small CSS parser, not a reach into Pygments' internal `Style` class
iteration. `HtmlFormatter(style=name).get_style_defs()` is Pygments' public, documented mechanism
for exporting a style's fully-resolved token colors — each rule's trailing comment
(`/* Comment.Hashbang */`) already names the token in the same dotted form our own
`CodeAttributes.Value` raw values use (just missing the leading `Token.`), so no separate
short-class-name table is needed. Because `get_style_defs()` emits every standard token fully
resolved (not just explicit overrides), this script does its own pruning pass afterward — dropping
any token whose resolved style is identical to its parent's — to produce the same sparse,
cascade-friendly table `CodeAttributes.Value.parent` expects at runtime.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path

from pygments.formatters import HtmlFormatter
from pygments.styles import get_style_by_name
from pygments.token import Token

ROOT = Path(__file__).resolve().parent.parent.parent
CODE_ATTRIBUTES_SWIFT = ROOT / "Modules/DesignSystemKit/Sources/CodeAttributes.swift"
THEMES_DIR = ROOT / "Modules/DesignSystemKit/Sources/Themes"

# Swift theme type name -> real Pygments style name.
THEMES = {
    "MonokaiTheme": "monokai",
    "DraculaTheme": "dracula",
    "EmacsTheme": "emacs",
    "ArduinoTheme": "arduino",
    "PygmentsTheme": "default",
    "ColorfulTheme": "colorful",
    "AbapTheme": "abap",
    "AlgolTheme": "algol",
    "AlgolNuTheme": "algol_nu",
    "AutumnTheme": "autumn",
    "BorlandTheme": "borland",
    "BwTheme": "bw",
    "CoffeeTheme": "coffee",
    "FriendlyTheme": "friendly",
    "FriendlyGrayscaleTheme": "friendly_grayscale",
    "FruityTheme": "fruity",
    "GithubDarkTheme": "github-dark",
    "GruvboxDarkTheme": "gruvbox-dark",
    "GruvboxLightTheme": "gruvbox-light",
    "IgorTheme": "igor",
    "InkpotTheme": "inkpot",
    "LightbulbTheme": "lightbulb",
    "LilypondTheme": "lilypond",
    "LovelaceTheme": "lovelace",
    "ManniTheme": "manni",
    "MaterialTheme": "material",
    "MurphyTheme": "murphy",
    "NativeTheme": "native",
    "NordTheme": "nord",
    "NordDarkerTheme": "nord-darker",
    "OneDarkTheme": "one-dark",
    "ParaisoDarkTheme": "paraiso-dark",
    "ParaisoLightTheme": "paraiso-light",
    "PastieTheme": "pastie",
    "PerldocTheme": "perldoc",
    "RainbowDashTheme": "rainbow_dash",
    "RrtTheme": "rrt",
    "SasTheme": "sas",
    "SolarizedDarkTheme": "solarized-dark",
    "SolarizedLightTheme": "solarized-light",
    "StarofficeTheme": "staroffice",
    "StataDarkTheme": "stata-dark",
    "StataLightTheme": "stata-light",
    "TangoTheme": "tango",
    "TracTheme": "trac",
    "VimTheme": "vim",
    "VsTheme": "vs",
    "XcodeTheme": "xcode",
    "ZenburnTheme": "zenburn",
}

CSS_RULE = re.compile(r"^\.[\w-]+\s*\{\s*(?P<decls>[^}]*)\}\s*/\*\s*(?P<name>.*?)\s*\*/\s*$")


def normalize_hex(value: str | None) -> str | None:
    """`#RRGGBB` (lowercase, `#`-prefixed) or `None` — CSS declarations and
    `Style.style_for_token` disagree on both the `#` prefix and case, so every `Style` is built
    through this to keep equality comparisons (`sparse`, the default-style skip) meaningful."""
    if not value:
        return None
    return f"#{value.lstrip('#').lower()}"


@dataclass(frozen=True)
class Style:
    fg: str | None
    bg: str | None
    bold: bool
    italic: bool
    underline: bool

    def __post_init__(self) -> None:
        object.__setattr__(self, "fg", normalize_hex(self.fg))
        object.__setattr__(self, "bg", normalize_hex(self.bg))


def parse_declarations(decls: str) -> Style:
    fg = bg = None
    bold = italic = underline = False
    for part in decls.split(";"):
        part = part.strip()
        if not part or ":" not in part:
            continue
        prop, _, value = part.partition(":")
        prop, value = prop.strip(), value.strip()
        if prop == "color":
            fg = value
        elif prop == "background-color":
            bg = value
        elif prop == "font-weight" and value == "bold":
            bold = True
        elif prop == "font-style" and value == "italic":
            italic = True
        elif prop == "text-decoration" and value == "underline":
            underline = True
    return Style(fg=fg, bg=bg, bold=bold, italic=italic, underline=underline)


def parent_of(token: str) -> str | None:
    if "." not in token:
        return None
    return token.rsplit(".", 1)[0]


def resolved_styles(style_name: str) -> dict[str, Style]:
    """Every standard token this style defines, keyed by full `Token.X.Y` path, resolved (a
    child not explicitly styled by the theme still gets its inherited color here — Pygments does
    the cascade for us, we just read the result off each rule's trailing token-name comment)."""
    css = HtmlFormatter(style=style_name).get_style_defs()
    styles: dict[str, Style] = {}
    for line in css.splitlines():
        match = CSS_RULE.match(line.strip())
        if not match:
            continue
        styles[f"Token.{match.group('name')}"] = parse_declarations(match.group("decls"))
    return styles


def default_style(style_name: str) -> Style:
    root = get_style_by_name(style_name).style_for_token(Token)
    return Style(
        fg=root["color"], bg=root["bgcolor"], bold=root["bold"], italic=root["italic"],
        underline=root["underline"],
    )


def sparse(styles: dict[str, Style]) -> dict[str, Style]:
    """Drop any token whose resolved style is identical to its parent's — same cascade
    `CodeTheme.getFormat(token:)` walks at runtime, so anything dropped here is recovered there."""
    return {
        token: style
        for token, style in styles.items()
        if styles.get(parent_of(token) or "") != style
    }


def load_token_case_names() -> dict[str, str]:
    """Parses `CodeAttributes.Value`'s case list directly from its Swift source — avoids keeping
    a second, driftable copy of the rawValue -> case-name mapping in this script."""
    source = CODE_ATTRIBUTES_SWIFT.read_text()
    return {token: case_name for case_name, token in
            re.findall(r'case\s+`?(\w+)`?\s*=\s*"(Token[\w.]*)"', source)}


def swift_hex(value: str, bg_fallback: str) -> str:
    hex_value = (value or bg_fallback).lstrip("#")
    return f'Color(fromHex: "#{hex_value}")!'


def swift_text_format(style: Style, page_bg: str) -> str:
    args = [f"fg: {swift_hex(style.fg, '000000')}", f"bg: {swift_hex(style.bg, page_bg)}"]
    if style.bold:
        args.append("bold: true")
    if style.italic:
        args.append("italic: true")
    if style.underline:
        args.append("underline: true")
    return f"TextFormat({', '.join(args)})"


def generate_theme_source(type_name: str, style_name: str, case_names: dict[str, str]) -> str:
    style = get_style_by_name(style_name)
    page_bg = style.background_color or "#ffffff"
    all_styles = resolved_styles(style_name)
    default = default_style(style_name)

    entries = []
    for token, case_name in sorted(case_names.items(), key=lambda kv: kv[1]):
        resolved = all_styles.get(token)
        if resolved is None or resolved == default:
            continue
        entries.append((token, case_name, resolved))

    sparse_tokens = sparse({token: resolved for token, _, resolved in entries})
    lines = [
        f"      .{case_name}: {swift_text_format(resolved, page_bg)},"
        for token, case_name, resolved in entries
        if token in sparse_tokens
    ]

    return f"""\
// GENERATED by Tools/GenerateThemes/generate_themes.py from Pygments' own "{style_name}" style —
// do not hand-edit. Re-run the script (see its module docstring) to refresh after a Pygments
// version bump instead.
import SwiftUI

public struct {type_name}: CodeTheme {{
  public init() {{}}
  public func getBgColor() -> Color {{ {swift_hex(page_bg, "ffffff")} }}

  public var defaultFormat: TextFormat {{ {swift_text_format(default, page_bg)} }}

  public var styles: [CodeAttributes.Value: TextFormat] {{
    [
{chr(10).join(lines)}
    ]
  }}
}}
"""


def main() -> None:
    case_names = load_token_case_names()
    for type_name, style_name in THEMES.items():
        source = generate_theme_source(type_name, style_name, case_names)
        (THEMES_DIR / f"{type_name}.swift").write_text(source)
        print(f"wrote {type_name}.swift ({style_name})")


if __name__ == "__main__":
    main()
