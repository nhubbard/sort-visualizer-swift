# HIS-02 signed-in CloudKit result (2026-10-03)

The supported Mac Catalyst app was run on a signed-in Mac with its normal
`ModelConfiguration(cloudKitDatabase: .automatic)` and app-group store. The server endpoint was
the development **private** database for `iCloud.com.nhubbard.Sort2.mobile`, accessed with a
short-lived CloudKit Console user token in the ignored `Tools/CloudKitCleanup/.user-token` file.
No token or private history values are stored here.

| Check | Observation |
| --- | --- |
| Failed primary store | `AnalyticsServiceTests.localFallbackRetainsHistoryAcrossContainerRecreation` passed in `/private/tmp/sort-contract-his02-local-1.xcresult` (PersistenceKit 10/10). A broken primary URL selected a file-backed local fallback, and reopening the file recovered the record. |
| App save | `testWriteCanaryOnFirstDevice` passed in `/private/tmp/sort-contract-his02-mac-write-export.xcresult`; the app saved `his02-canary-app-server-20261003-f` through `AnalyticsService.record` and read back `count:1`. |
| Upload | `query.py his02-canary-app-server-20261003-f` returned exactly one `CD_BigORecord` in the CloudKit private database. Core Data logged a successful CloudKit setup for the normal app-group store. The upload lagged the local save while that store imported a large existing history corpus. |
| Server deletion and import | The app first showed `count:1` in its normal store in `/private/tmp/sort-contract-his02-mac-inbound-delete.xcresult` (this run was stopped after the server deletion to relaunch with a fresh-context probe). `delete.py` deleted exactly the matching canary by its CloudKit record name; `query.py` then returned `count:0`. After relaunch, `testDeletedCanaryIsAbsentAfterRelaunch` passed in `/private/tmp/sort-contract-his02-mac-inbound-relaunch.xcresult`, reading `count:0` from the normal SwiftData store. Core Data logged a successful import with `madeChanges: 1` at 22:10:16 local time. |
| Cleanup | An earlier synthetic canary (`his02-canary-app-server-20261003-e`) was also deleted by exact record name; its absence in the app passed `/private/tmp/sort-contract-his02-mac-cleanup-e.xcresult`. A final build and app check passed in `/private/tmp/sort-contract-his02-final-ui.xcresult`. `query.py` returned zero for every attempted marker `a` through `f`. The temporary independent-store experiment was removed from source and its test store was deleted by the sandboxed app. |

The saved record and the remotely deleted record are the same synthetic canary. This exercises
the production `AnalyticsService` write path, SwiftData's CloudKit export, the authenticated
private database, and SwiftData's import into the app's normal store. The receive check used an
app relaunch because the live process had not received a deletion notification during its first
observation window. This run establishes a Mac Catalyst/CloudKit round trip; it does not establish
an iPad UI result.
