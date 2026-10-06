# Cyberdeck Archive (public summary)

Long-term retention for superseded lab assets. **Never delete** - move into a dated bucket instead.

## Layout

```
Archive/
|-- README.md
`-- YYYY-MM-DD/
    |-- docs/
    |-- installers/
    |-- snapshots/
    `-- ova/
```

Prefer **dated buckets**. Active OVA/snapshot working copies live under `VMs/exports/`; only retired copies move here.

## Rules (summary)

1. Never delete project keepers, docs, snapshots, or OVAs - archive under the day's bucket.
2. Log every archive move in the changelog.
3. Never touch application installs, games, or OS/system files.
4. Controlled / export-restricted installers and VM images stay on local fixed disk only, with a second local copy (never cloud).
5. Paths stay project-relative; no personal paths or hostnames.