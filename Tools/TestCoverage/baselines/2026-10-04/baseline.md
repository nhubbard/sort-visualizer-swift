# App-owned coverage

Source-line union: **35641/37779 (94.34%)**

Source snapshot verified: **yes**. Measured result test summaries verified: **yes**.

Platform totals are separate; the source-line union can include both platform builds.

## Platforms

| Platform | Covered | Executable | Percent |
| --- | ---: | ---: | ---: |
| catalyst | 33498 | 36788 | 91.06% |
| ios | 10033 | 37119 | 27.03% |

## Targets

| Target | Covered | Executable | Percent |
| --- | ---: | ---: | ---: |
| AUv3Extension | 101 | 159 | 63.52% |
| AlgorithmKit | 389 | 393 | 98.98% |
| AudioEngineKit | 141 | 145 | 97.24% |
| BuiltInAlgorithms | 22962 | 23394 | 98.15% |
| BuiltInVisualizers | 731 | 732 | 99.86% |
| DesignSystemKit | 1933 | 1987 | 97.28% |
| HomeFeature | 19 | 19 | 100.0% |
| IntentsKit | 389 | 639 | 60.88% |
| MathRenderingKit | 135 | 135 | 100.0% |
| PersistenceKit | 335 | 387 | 86.56% |
| SettingsFeature | 142 | 190 | 74.74% |
| SettingsKit | 153 | 153 | 100.0% |
| SortAudioBridgeKit | 255 | 266 | 95.86% |
| SortAudioCore | 93 | 93 | 100.0% |
| SortAudioUnitKit | 133 | 138 | 96.38% |
| SortEngineKit | 930 | 955 | 97.38% |
| SortFeature | 3637 | 4403 | 82.6% |
| SortSymphony.app | 623 | 960 | 64.9% |
| ToneKitAVFoundation | 36 | 36 | 100.0% |
| ToneKitDSP | 247 | 247 | 100.0% |
| VisualizationKit | 53 | 53 | 100.0% |
| ZstdKit | 2204 | 2295 | 96.03% |

## Largest measured gaps

| File | Uncovered lines |
| --- | ---: |
| `App/Sources/ContentView.swift` | 204 |
| `Modules/SortFeature/Sources/RunControlBar.swift` | 150 |
| `Modules/BuiltInAlgorithms/Sources/Hybrid/ChaliceSort.swift` | 87 |
| `Modules/BuiltInAlgorithms/Sources/Hybrid/AdaptiveGrailSort.swift` | 75 |
| `Modules/BuiltInAlgorithms/Sources/Shuffles/PDQAdversaryShuffle.swift` | 73 |
| `Modules/SortFeature/Sources/CloudKitCanaryControls.swift` | 73 |
| `App/Sources/Sort2App.swift` | 66 |
| `Modules/SortFeature/Sources/MetalShapeGeometry.swift` | 59 |
| `App/AUv3Extension/Sources/SortAudioUnitParameterView.swift` | 58 |
| `App/Sources/SortCommands.swift` | 58 |
| `Modules/SortFeature/Sources/SortSession.swift` | 57 |
| `Modules/SortFeature/Sources/BigOCorrelationChart.swift` | 55 |
| `Modules/PersistenceKit/Sources/AnalyticsService.swift` | 52 |
| `Modules/ZstdKit/Sources/Internal/Encode/MatchFinder.swift` | 51 |
| `Modules/SortFeature/Sources/SortView.swift` | 49 |
| `Modules/SettingsFeature/Sources/SettingsView.swift` | 48 |
| `Modules/SortFeature/Sources/MetalTriangleRenderer.swift` | 40 |
| `Modules/SortFeature/Sources/BigOCorrelationDetailView.swift` | 39 |
| `Modules/BuiltInAlgorithms/Sources/Templates/PDQSortingTemplate.swift` | 38 |
| `Modules/SortFeature/Sources/MetalDisparityChordsRenderer.swift` | 37 |

## Changed executable lines

860/1262 (68.15%) since `1f3837138d6c003e37af65566f740546a96b5f36`; 0 changed source files have no coverage records.

## Unmeasured production sources

14 source files have no coverage records. A file here may contain declarations only, belong to an unrun platform target, or represent a real test gap.
AUv3 extension files without records: **0**.
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
