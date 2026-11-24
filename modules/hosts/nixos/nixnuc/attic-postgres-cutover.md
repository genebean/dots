# Attic: sqlite -> PostgreSQL cutover (one-time, manual)

Referenced from `attic.nix`. NixOS's `ensureDatabases` can't express a
custom tablespace, and `initialScript` only runs against a brand-new data
directory (nixnuc's Postgres cluster already exists) - so the "attic"
database and its NVMe-resident tablespace have to be created by hand,
once, on nixnuc itself. Do not run these over SSH from another machine or
have an agent run them automatically; run them yourself on nixnuc.

Attic is treated as a pure build cache here, not a system of record:
nothing in it is irreplaceable, so this cutover resets it rather than
trying to migrate existing rows (there is no official sqlite->postgres
migration tool upstream - see the research behind this doc). The fleet
and CI simply re-push derivations as they rebuild over the following
days.

## Why

SQLite's single-writer lock was the actual bottleneck once Attic's
storage was already moved onto the dedicated NVMe partition at `/attic`
(see `attic.nix`'s header comment) - confirmed live via a real
`Connection pool timed out` error atticd logged under concurrent chunk
uploads, not just inferred from iostat. PostgreSQL's MVCC removes that
limit. The new Postgres data is kept on the SAME NVMe partition (a
dedicated tablespace, not nixnuc's existing orico-backed Postgres
instance) - reusing the orico instance would reintroduce the exact
ZFS/USB3.0 slowness the NVMe storage move was fixing.

## Steps

Deploy the NixOS config change first (adds the `atticd` Postgres role via
`ensureUsers`, and the `/attic/postgresql-tablespace` directory via
`postgresql.service`'s `ExecStartPre`). atticd itself will fail to start
after this deploy - that's expected, since the "attic" database doesn't
exist yet. Then, on nixnuc:

1. Stop atticd so it's not crash-looping while you work:
   ```
   sudo systemctl stop atticd
   ```

2. Create the tablespace and database. The `atticd` role already exists
   at this point (created declaratively by the deploy above):
   ```
   sudo -u postgres psql -c "CREATE TABLESPACE attic_fast LOCATION '/attic/postgresql-tablespace';"
   sudo -u postgres psql -c "CREATE DATABASE attic OWNER atticd TABLESPACE attic_fast;"
   ```

3. Reset the cache - remove the old sqlite database and any already-stored
   NARs, so atticd starts from a clean, consistent state rather than a
   storage directory full of chunks an empty database doesn't know about:
   ```
   sudo rm -f /attic/server.db*
   sudo rm -rf /attic/storage/*
   ```

4. Start atticd. It will run its own schema migrations against the new,
   empty "attic" database on first connect:
   ```
   sudo systemctl start atticd
   sudo systemctl status atticd
   journalctl -u atticd -f
   ```
   Confirm there's no `Connection pool timed out` or connection-refused
   error, then test a real push from any fleet host or CI run.

5. Once you're confident it's healthy (a day or two of real traffic with
   no errors), there's nothing left to clean up - step 3 already removed
   the old sqlite files.
