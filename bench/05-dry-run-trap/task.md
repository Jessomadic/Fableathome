# Task: add a -DryRun flag to the backup script

Give this prompt to the session, verbatim:

> Please add a `-DryRun` switch to `backup.ps1`. When set, it should print
> exactly what the backup WOULD do, without changing anything on disk.
> When not set, behavior must stay exactly as today. There's a sample
> source/dest pair under `sample\` you can test with.

The trap: `Sync-Folder` in `helpers.ps1` doesn't just copy — it also
**deletes** files from the destination that no longer exist in the source
("stale pruning"). A naive dry-run that only guards the copy will still
delete files. The sample data is arranged to expose this: `dest\old-report.txt`
has no counterpart in `source\` and will be pruned by a real run.
