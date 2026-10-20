# Central Dolt/Beads server - pre-deploy runbook

Companion to `dolt-beads-server.nix`. genebean/dots#825 (design), genebean/agent-ideas#5
(original proposal), `agents-beads-collaboration-3kt` (Beads coordination).

This is a **runbook, not a script** - run each step deliberately, in order,
checking output before moving on.

**Status (2026-10-19): steps 0-4 complete for `gene` and `claude-rp`.**
Server is live on nixnuc, real data migrated and verified (33 issues),
all 8 identities provisioned. Still open: steps 4 (client config) for the
five Hermes agents and `mr-c`, and step 5's decommission of the embedded
copy. See notes inline below and `agents-beads-collaboration-3kt` for the
full history, including bugs found only by actually deploying/migrating
(wrong Dolt version, wrong config field name, `ProtectHome` vs. Dolt's
`$HOME/.dolt`, root-owned ZFS dataset, `--global` not overriding the
database name on `--reinit-local`, `dolt_server_port` defaulting to `0`).

## Why this exists separately from the Nix module

`dolt-beads-server.nix` is fully wired and evaluates cleanly (ZFS dataset,
ACME cert, systemd service, native-Dolt-backup-then-restic), but it
deliberately has **no per-agent SQL user provisioning** in it: sops-nix
validates that every `sops.secrets.<name>` declaration actually exists in
the encrypted sops file at `nix eval` time. None of those secrets exist
yet, so wiring them into live Nix code now would just break every future
eval until they're created. This runbook is what to actually do once
that's ready.

## 0. Pre-deploy checklist

- [x] Confirm which agents/hosts need their own Dolt login. Design decision
      (dots#825): **per-agent (and per-Claude-identity), not per-host** -
      mirrors the existing per-agent secret convention (Buzz identity,
      Forgejo token, etc. are already distinct per Hermes agent). "Every
      agent, including you [Claude], should have its own identity" from the
      original design discussion turned out to mean **you** are actually two
      separate identities - direct human CLI use vs. interactive Claude Code
      sessions - plus a third, pre-existing one (Mr. C) that hadn't been
      named yet. Final consumer list:
      - `leo`, `charlie`, `danny`, `cj`, `sam` - Hermes agents on `tcan-left`
      - `gene` - direct human `bd`/SQL CLI use
      - `claude-rp` - interactive Claude Code sessions on rainbow-planet
        (this laptop; the naming convention is `claude-<host-suffix>`, so a
        future second interactive-session host gets its own analogous name,
        e.g. a hypothetical `claude-mm`)
      - `mr-c` - the Buzz-side Claude Code agent (`~/.buzz`); already shares
        the embedded `agents-beads-collaboration` DB today, so this just
        formalizes its identity for the central-server migration
- [x] For each one, create a secret in `modules/shared/secrets.yaml` via
      `sops modules/shared/secrets.yaml` (never generate the password value
      yourself and never have an agent/Claude generate or see it - this is
      your own call to make, on your own machine). Suggested naming:
      `dolt_beads_<identity>_password` (e.g. `dolt_beads_leo_password`,
      `dolt_beads_gene_password`, `dolt_beads_claude_rp_password`,
      `dolt_beads_mr_c_password`) - bare password value, no `KEY=value`
      wrapping needed since these get read directly by SQL statements below,
      not through `envFileAs`.
- [x] Each identity's Dolt SQL login is separate from its `BEADS_ACTOR`
      audit-trail label (step 4) - both get set to the same identity name,
      but they're two different config knobs. Resolved for `claude-rp`:
      `~/.claude/settings.json`'s `env` block on rainbow-planet
      (`BEADS_ACTOR`, `BEADS_DOLT_SERVER_USER`, `BEADS_DOLT_SERVER_TLS`,
      `BEADS_DOLT_PASSWORD`) - deliberately *not* managed via home-manager/
      sops; an attempt at that surfaced real cross-host-type complexity
      (home-manager's own sops module isn't wired into NixOS hosts the way
      it is for Darwin/HM-only) that wasn't worth resolving for this.
      Confirmed working: `events.actor` in `beads_global` shows `claude-rp`
      for writes made this way, vs. the generic Dolt-commit "Author" field
      bd history displays (unaffected by `--actor`, a separate thing).

## 1. Safety-net backup of the current embedded database

Run this **before touching anything else**, on whichever machine currently
hosts the live `agents-beads-collaboration` working copy:

```sh
cd ~/repos/agents-beads-collaboration   # or wherever it actually lives
tar czf ~/Downloads/agents-beads-collaboration-pre-migration-$(date +%Y%m%d).tar.gz .beads/
```

Confirm the tarball exists and has a reasonable size before proceeding.
This is the restore point if anything below goes wrong - restorable by
extracting it back over `.beads/` and reverting to embedded mode.

## 2. Deploy the server (dry-activate first)

```sh
nix run .#deploy-rs -- .#nixnuc --dry-activate --skip-checks --hostname <nixnuc-lan-ip>
# review output, then:
nix run .#deploy-rs -- .#nixnuc --skip-checks --hostname <nixnuc-lan-ip>
```

At this point the server is running with **no users provisioned except
Dolt's own auto-created, no-password `root`** on first launch. The service
is reachable (port open per design decision - nixnuc's physical firewall is
the real internet boundary, not this), so minimize the gap between this
step and step 3.

## 3. Copy the data and provision users

```sh
# on nixnuc, as root:
systemctl stop dolt-beads
rsync -a /path/to/extracted/.beads/embeddeddolt/agents_beads_collaboration/.dolt/ /orico/dolt-beads/beads_global/.dolt/
chown -R dolt-beads:dolt-beads /orico/dolt-beads
systemctl start dolt-beads
```

**Done, 2026-10-19.** Actual command used was `root`@`localhost` (Dolt's
auto-created superuser is localhost-scoped, not `@'%'` - a MySQL client
has to run this from nixnuc itself, over loopback, not remotely):

```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY '<password>'; -- reused gene's password here; no dedicated root secret was created

CREATE USER 'leo'@'%' IDENTIFIED BY '<leo-password>';
CREATE USER 'charlie'@'%' IDENTIFIED BY '<charlie-password>';
CREATE USER 'danny'@'%' IDENTIFIED BY '<danny-password>';
CREATE USER 'cj'@'%' IDENTIFIED BY '<cj-password>';
CREATE USER 'sam'@'%' IDENTIFIED BY '<sam-password>';
CREATE USER 'gene'@'%' IDENTIFIED BY '<gene-password>';
CREATE USER 'claude-rp'@'%' IDENTIFIED BY '<claude-rp-password>';
CREATE USER 'mr-c'@'%' IDENTIFIED BY '<mr-c-password>';

-- GRANT ALL ON beads_global.* alone turned out insufficient: Dolt's
-- --global bootstrap/migration path runs a literal CREATE DATABASE and a
-- "fresh-bootstrap history" schema check, both of which need *.* scope,
-- not db-scoped privileges (standard MySQL's db-scoped CREATE DATABASE
-- exception isn't replicated in Dolt's go-mysql-server). Went broad
-- instead of chasing each one individually - the real trust boundary
-- here is the physical firewall + per-identity passwords, not SQL-level
-- isolation between mutually-trusted identities:
GRANT ALL PRIVILEGES ON *.* TO 'leo'@'%';
GRANT ALL PRIVILEGES ON *.* TO 'charlie'@'%';
GRANT ALL PRIVILEGES ON *.* TO 'danny'@'%';
GRANT ALL PRIVILEGES ON *.* TO 'cj'@'%';
GRANT ALL PRIVILEGES ON *.* TO 'sam'@'%';
GRANT ALL PRIVILEGES ON *.* TO 'gene'@'%';
GRANT ALL PRIVILEGES ON *.* TO 'claude-rp'@'%';
GRANT ALL PRIVILEGES ON *.* TO 'mr-c'@'%';

FLUSH PRIVILEGES;
```

No MySQL client is installed on nixnuc itself - `nix shell nixpkgs#mariadb
--command mysql -h 127.0.0.1 -P 3307 -u root --ssl -p` worked (note:
`--ssl`, not `--ssl-mode=REQUIRED` - this client version's flag differs).

## 4. Configure clients

**Done for `gene` and `claude-rp`; still pending for leo/charlie/danny/cj/
sam (tcan-left Hermes agents) and `mr-c` (Buzz agent, `~/.buzz`).**

On the one project directory that was already running the embedded copy
(`~/repos/agents-beads-collaboration` on rainbow-planet, resolved from
anywhere via the already-existing `BEADS_DIR` env var -
`agents-beads-collaboration-66y` tracks making that declarative):

```sh
cd ~/repos/agents-beads-collaboration
export BEADS_DOLT_PASSWORD='<gene-password>'
export BEADS_DOLT_SERVER_TLS=1
BD_ALLOW_REMOTE_MIGRATE=1 bd init --server --external --global --reinit-local \
  --server-host=dolt-beads.home.technicalissues.us \
  --server-user=gene
unset BEADS_DOLT_PASSWORD
```

Three things this surfaced, none obvious from `--help` alone:

- **`BD_ALLOW_REMOTE_MIGRATE=1` was required**: the embedded copy had
  self-migrated far ahead of a brand-new server database (45 pending
  migrations) and `bd` refuses to auto-apply that to a *shared* database
  without explicit consent (locks out any older co-resident client). No
  actual risk here - `gene` was the first real client of this new server.
- **`--global` did not override `--reinit-local`'s existing database
  name**: it silently kept the old per-project name
  (`agents_beads_collaboration`) instead of switching to `beads_global`,
  so the migration ran against a brand-new *empty* database rather than
  the real one. Fixed after the fact with `bd dolt set database
  beads_global` - no need to redo the init/migrate dance. (The orphaned
  empty database this left behind on the server was later `DROP`ped.)
- **`dolt_server_port` was persisted as `0`** instead of defaulting to
  `3307` when `--server-port` wasn't passed explicitly. Fixed with `bd
  dolt set port 3307`.

For `claude-rp`, no `bd init` was needed at all - it's the exact same
local project/directory as `gene`, just a different runtime identity via
env vars (`BEADS_DOLT_SERVER_USER`/`BEADS_DOLT_PASSWORD` are resolved
fresh per-invocation, not baked in at init time). `gene`'s own terminal
needs a way to supply its password without exporting it every session -
`bd`'s credentials file (`~/.config/beads/credentials`, INI, section
keyed by `host:port`) is the documented mechanism; an attempt to manage
that file declaratively was deliberately backed out (see step 0's note on
`claude-rp`) in favor of just creating it manually.

Verify with `bd dolt show` (not `bd dolt status` - that one's for the
embedded-mode engine), then `bd ready`/`bd list` and confirm the existing
issues/epics/history are all present and unchanged.

## 5. Verify, then decommission the embedded copy

- [x] Two separate clients see the same records - confirmed for `gene` and
      `claude-rp`.
- [x] A write from one is visible from the other without manual sync -
      confirmed: `claude-rp`'s write to `agents-beads-collaboration-3kt`
      landed in `beads_global` directly (same server, same schema; there's
      no per-client copy to sync in server mode).
- [x] `bd dolt show` on each client confirms server mode, not embedded.
- [ ] Only after leo/charlie/danny/cj/sam/`mr-c` are also migrated (not yet):
      the old `.beads/embeddeddolt/` on rainbow-planet can be removed - keep
      the tarball from step 1 regardless.

## 6. Wire the restic backup into verification

`dolt-beads-backup.service`/timer is already deployed as part of the Nix
module (01:00 daily, before this host's own 02:00 restic run). After step 3,
manually run `systemctl start dolt-beads-backup` once and confirm
`/var/backup/dolt-beads` has real content before trusting the automated
schedule.
