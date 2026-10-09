# REF-02 description prose verification

The corpus contains 196 built-in algorithm descriptions and one scaffold description. The
structural audit checks that each algorithm has a description of at least 100 words; that the
scaffold and all descriptions use only permitted paragraph and inline Markdown; and that links,
emphasis, quotation marks, mathematical notation, wording, and whitespace follow the project
rules. It now also rejects duplicate descriptions, conversational prompts, and openings that
omit the selected variant's qualifier (iterative, recursive, stackless, unstable, optimized,
unoptimized, or simplified). The audit passed all 197 files.

The variant check found 14 descriptions that introduced the base sort before identifying the
selected variant. Their openings now name the specific form. Three descriptions contained
conversational instructions; those passages were rewritten as neutral prose. The rebuilt
`AlgorithmDetails.algz` passed the packer's outer-header, SHA-256, zstd-checksum, and
source-manifest verification.

The existing `AlgorithmDetailCorpusUITests` suite has rendered and retained top screenshots for
all 196 descriptions at standard and 360-point detail widths on both iPad and Mac Catalyst.
The three longest descriptions by word count are Introspective Circle Sort (Recursive), Laziest
Stable Sort, and Stackless Rotate Merge Sort (785, 696, and 764 words respectively). The new
focused UI test scrolls each 360-point page to the Complexity section, asserts that its last
description sentence is present, and retains an end-of-description screenshot. All three
rendered to the final sentence without horizontal clipping or overlap with Complexity in the
reviewed iPad and Catalyst captures.

Results:

- iPad Air 13-inch (M4), iOS 27 simulator: `/private/tmp/ref02-ipad-long-prose-2.xcresult`,
  1 passed, 0 failed, 0 skipped; screenshots in `/private/tmp/ref02-ipad-long-prose-export`.
- Mac Catalyst: `/private/tmp/ref02-catalyst-long-prose-3.xcresult`, 1 passed, 0 failed,
  0 skipped; screenshots in `/private/tmp/ref02-catalyst-long-prose-export`.
- Corpus audit: `python3 Tools/AlgorithmDetailsAudit/audit.py`, 196 algorithms and 197
  descriptions checked, no errors.

The longest-prose test checks the complete rendered ending and scrollability. It does not
claim that an automated test can judge every factual statement; the prose audit and focused
edits cover the specified editorial rules, and the retained corpus screenshots remain
available for further review.
