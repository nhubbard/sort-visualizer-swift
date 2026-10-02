# App-owned coverage

Source-line union: **34995/36785 (95.13%)**

Source snapshot verified: **yes**. Measured result test summaries verified: **yes**.

Platform totals are separate; the source-line union can include both platform builds.

## Platforms

| Platform | Covered | Executable | Percent |
| --- | ---: | ---: | ---: |
| catalyst | 32850 | 35962 | 91.35% |
| ios | 10178 | 36293 | 28.04% |

## Targets

| Target | Covered | Executable | Percent |
| --- | ---: | ---: | ---: |
| AlgorithmKit | 364 | 366 | 99.45% |
| AudioEngineKit | 131 | 132 | 99.24% |
| BuiltInAlgorithms | 22714 | 23393 | 97.1% |
| BuiltInVisualizers | 727 | 728 | 99.86% |
| DesignSystemKit | 1933 | 1987 | 97.28% |
| HomeFeature | 19 | 19 | 100.0% |
| IntentsKit | 382 | 617 | 61.91% |
| MathRenderingKit | 128 | 128 | 100.0% |
| PersistenceKit | 310 | 317 | 97.79% |
| SettingsFeature | 160 | 177 | 90.4% |
| SettingsKit | 132 | 132 | 100.0% |
| SortAudioBridgeKit | 245 | 257 | 95.33% |
| SortAudioCore | 93 | 93 | 100.0% |
| SortAudioUnitKit | 133 | 138 | 96.38% |
| SortEngineKit | 906 | 935 | 96.9% |
| SortFeature | 3464 | 3943 | 87.85% |
| SortSymphony.app | 614 | 792 | 77.53% |
| ToneKitAVFoundation | 36 | 36 | 100.0% |
| ToneKitDSP | 247 | 247 | 100.0% |
| VisualizationKit | 53 | 53 | 100.0% |
| ZstdKit | 2204 | 2295 | 96.03% |

## Largest measured gaps

| File | Uncovered lines |
| --- | ---: |
| `App/Sources/ContentView.swift` | 97 |
| `Modules/BuiltInAlgorithms/Sources/Shuffles/PDQAdversaryShuffle.swift` | 89 |
| `Modules/BuiltInAlgorithms/Sources/Hybrid/ChaliceSort.swift` | 87 |
| `Modules/BuiltInAlgorithms/Sources/Hybrid/AdaptiveGrailSort.swift` | 75 |
| `Modules/BuiltInAlgorithms/Sources/Hybrid/FlanSort.swift` | 67 |
| `Modules/SortFeature/Sources/MetalShapeGeometry.swift` | 66 |
| `Modules/BuiltInAlgorithms/Sources/Templates/GrailSortingTemplate.swift` | 62 |
| `Modules/SortFeature/Sources/SortSession.swift` | 59 |
| `App/Sources/SortCommands.swift` | 58 |
| `Modules/SortFeature/Sources/MetalTriangleRenderer.swift` | 55 |
| `Modules/SortFeature/Sources/RunControlBar.swift` | 55 |
| `Modules/ZstdKit/Sources/Internal/Encode/MatchFinder.swift` | 51 |
| `Modules/SortFeature/Sources/MetalDisparityChordsRenderer.swift` | 48 |
| `Modules/SortFeature/Sources/MetalHanoiTowersRenderer.swift` | 45 |
| `Modules/BuiltInAlgorithms/Sources/Templates/UnstableGrailSortingTemplate.swift` | 42 |
| `Modules/BuiltInAlgorithms/Sources/Templates/PDQSortingTemplate.swift` | 33 |
| `Modules/IntentsKit/Sources/VisualizerSettingIntents.swift` | 25 |
| `Modules/BuiltInAlgorithms/Sources/Hybrid/ImprovedBlockSelectionSort.swift` | 22 |
| `Modules/SortFeature/Sources/MetalRendererView.swift` | 21 |
| `App/Sources/Sort2App.swift` | 20 |

## Changed executable lines

58/63 (92.06%) since `HEAD`; 0 changed source files have no coverage records.

## Unmeasured production sources

16 source files have no coverage records. A file here may contain declarations only, belong to an unrun platform target, or represent a real test gap.
AUv3 extension files without records: **2**.
- `App/AUv3Extension/Sources/SortAudioUnitParameterView.swift`
- `App/AUv3Extension/Sources/SortAudioUnitViewController.swift`
- `Modules/AudioEngineKit/Sources/AudioPlaying.swift`
- `Modules/SortAudioCore/Sources/RemoteControlCommand.swift`
- `Modules/SortAudioCore/Sources/SortAudioEventSink.swift`
- `Modules/SortAudioCore/Sources/SortOperationKind.swift`
- `Modules/SortEngineKit/Sources/TapeArchiveError.swift`
- `Modules/SortFeature/Sources/AlgorithmDetailsArchiveError.swift`
- `Modules/SortFeature/Sources/DebugInstrumentsTrace.swift`
- `Modules/SortFeature/Sources/IncrementalBarRenderer.swift`
- `Modules/SortFeature/Sources/MetalIncrementalRenderer.swift`
- `Modules/ToneKitDSP/Sources/ToneCommand.swift`
- `Modules/VisualizationKit/Sources/DrawCommand.swift`
- `Modules/ZstdKit/Sources/Internal/Encode/MatchFinding.swift`
- `Modules/ZstdKit/Sources/ZstdEncodeError.swift`
- `Modules/ZstdKit/Sources/ZstdError.swift`

## Behavioral-only results

- `catalyst/ui`: 23 passed, 2 skipped; no line coverage attributed
