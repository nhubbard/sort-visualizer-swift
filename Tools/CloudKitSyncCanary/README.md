# HIS-02 CloudKit history canary

This is an opt-in test of the app's real SwiftData CloudKit store on supported iPadOS and Mac
Catalyst builds. For the full two-device test, both devices must run a development-signed build
and be signed into the same iCloud account. The test
creates one synthetic `BigORecord` whose algorithm ID starts with `his02-canary-`; it does not
appear in any real algorithm's chart. The last phase deletes it. Ordinary UI suites skip all
three canary tests.

Use the same marker suffix for all phases. Run `write` on device A, then `observe` on device B.
For a bidirectional check, use a second marker and reverse A and B. Run `delete` on each device
after both observations. The `observe` phase polls for up to five minutes; an upload can take
longer, so a timeout should be retried before treating it as a sync defect.

```sh
Tools/CloudKitSyncCanary/run.sh 'platform=iOS,id=<device-A-UDID>' write run-001 /private/tmp/his02-a-write.xcresult
Tools/CloudKitSyncCanary/run.sh 'platform=macOS,variant=Mac Catalyst' observe run-001 /private/tmp/his02-b-observe.xcresult
Tools/CloudKitSyncCanary/run.sh 'platform=iOS,id=<device-A-UDID>' delete run-001 /private/tmp/his02-a-delete.xcresult
Tools/CloudKitSyncCanary/run.sh 'platform=macOS,variant=Mac Catalyst' delete run-001 /private/tmp/his02-b-delete.xcresult
```

The runner edits a temporary `.xctestrun` plist to pass the opt-in marker to the test process.
It does not change the generated workspace or any source file. Keep the `.xcresult` bundles as
evidence and record the exact devices, account state, marker, and run times in the contract
matrix. A passing write phase proves the local save. A passing observation on the other device
proves that the marker crossed the CloudKit sync boundary. The local fallback test in
`AnalyticsServiceTests` separately checks that a failed primary store still preserves data
across a container recreation.

When only the Mac is available, verify the app-to-server leg with a private-database user token
from CloudKit Console. Keep the token in the ignored `Tools/CloudKitCleanup/.user-token` file,
then run `query.py` while the write phase keeps the app open and again after it finishes:

```sh
Tools/CloudKitSyncCanary/run.sh 'platform=macOS,variant=Mac Catalyst' write run-002 /private/tmp/his02-mac-write.xcresult
python3 Tools/CloudKitSyncCanary/query.py his02-canary-run-002
```

`query.py` reads only records matching that marker in the development private database and
prints their record names. A server-side match proves upload; it does not prove the app imported
history on a second device. For the receive path on one Mac, run `observe-delete` for a marker
already saved locally and visible in CloudKit. While that test is waiting, delete **only that
synthetic canary** with `delete.py`, which requires exactly one matching record and deletes it by
exact record name. The test first asserts
`count:1` in the normal SwiftData store, then waits for `count:0` after the server deletion.
This proves that the same store imports a remote change, without starting a second physical
device or importing the entire history into a fresh store. A local `count:1` in the write phase
alone proves only the save. The app can have a large
existing import queue, so server appearance may lag the local write. The write phase keeps the
app alive for 90 seconds by default; set `HIS02_EXPORT_HOLD_SECONDS=900` before `run.sh` for a
15-minute session when an import queue is large. In the two-device workflow, use the `delete`
phase once the observations are finished. In the one-Mac workflow, use `delete.py`, then run
`observe-absent` after relaunch if the live import has not arrived, and re-query for server
absence.

```sh
Tools/CloudKitSyncCanary/run.sh 'platform=macOS,variant=Mac Catalyst' observe-delete run-002 /private/tmp/his02-mac-delete-import.xcresult
# In another terminal, after the test has observed count:1:
python3 Tools/CloudKitSyncCanary/delete.py his02-canary-run-002
Tools/CloudKitSyncCanary/run.sh 'platform=macOS,variant=Mac Catalyst' observe-absent run-002 /private/tmp/his02-mac-absent.xcresult
```

The completed signed-in Mac result is recorded in [RESULTS.md](RESULTS.md).
