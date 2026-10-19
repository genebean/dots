# Central Dolt/Beads server - pre-deploy runbook

Companion to `dolt-beads-server.nix`. genebean/dots#825 (design), genebean/agent-ideas#5
(original proposal), `agents-beads-collaboration-3kt` (Beads coordination).

This is a **runbook, not a script** - run each step deliberately, in order,
checking output before moving on. Nothing here has been executed yet.

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

- [ ] Confirm which agents/hosts need their own Dolt login. Design decision
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
- [ ] For each one, create a secret in `modules/shared/secrets.yaml` via
      `sops modules/shared/secrets.yaml` (never generate the password value
      yourself and never have an agent/Claude generate or see it - this is
      your own call to make, on your own machine). Suggested naming:
      `dolt_beads_<identity>_password` (e.g. `dolt_beads_leo_password`,
      `dolt_beads_gene_password`, `dolt_beads_claude_rp_password`,
      `dolt_beads_mr_c_password`) - bare password value, no `KEY=value`
      wrapping needed since these get read directly by SQL statements below,
      not through `envFileAs`.
- [ ] Each identity's Dolt SQL login is separate from its `BEADS_ACTOR`
      audit-trail label (step 4) - both get set to the same identity name,
      but they're two different config knobs. For `claude-rp` specifically,
      something needs to export `BEADS_ACTOR=claude-rp` for interactive
      sessions on rainbow-planet (a shell env var, most likely) - not wired
      anywhere yet, just flagged here so it isn't forgotten at step 4.

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

Then, connected as root via `dolt sql -q` or a MySQL client against the new
server, lock down root and create the real per-agent accounts (password
values come from the sops secrets created in step 0 - read each one with
`sops -d --extract '["dolt_beads_<agent>_password"]' modules/shared/secrets.yaml`
**on your own machine**, never pasted into a Claude Code session):

```sql
ALTER USER 'root'@'%' IDENTIFIED BY '<a-password-only-you-know, or disable root entirely>';

CREATE USER 'leo'@'%' IDENTIFIED BY '<leo-password>';
CREATE USER 'charlie'@'%' IDENTIFIED BY '<charlie-password>';
CREATE USER 'danny'@'%' IDENTIFIED BY '<danny-password>';
CREATE USER 'cj'@'%' IDENTIFIED BY '<cj-password>';
CREATE USER 'sam'@'%' IDENTIFIED BY '<sam-password>';
CREATE USER 'gene'@'%' IDENTIFIED BY '<gene-password>';
CREATE USER 'claude-rp'@'%' IDENTIFIED BY '<claude-rp-password>';
CREATE USER 'mr-c'@'%' IDENTIFIED BY '<mr-c-password>';

GRANT ALL PRIVILEGES ON beads_global.* TO 'leo'@'%';
GRANT ALL PRIVILEGES ON beads_global.* TO 'charlie'@'%';
GRANT ALL PRIVILEGES ON beads_global.* TO 'danny'@'%';
GRANT ALL PRIVILEGES ON beads_global.* TO 'cj'@'%';
GRANT ALL PRIVILEGES ON beads_global.* TO 'sam'@'%';
GRANT ALL PRIVILEGES ON beads_global.* TO 'gene'@'%';
GRANT ALL PRIVILEGES ON beads_global.* TO 'claude-rp'@'%';
GRANT ALL PRIVILEGES ON beads_global.* TO 'mr-c'@'%';

FLUSH PRIVILEGES;
```

## 4. Configure clients

On each machine/agent, point `bd` at the new server (per-agent `BEADS_ACTOR`
is the separate, already-existing audit-trail layer - set it in each
agent's own environment, not here):

```sh
export BEADS_DOLT_PASSWORD='<this agent's own password>'
export BEADS_DOLT_SERVER_TLS=1
bd init --server --external --global \
  --server-host=dolt-beads.home.technicalissues.us \
  --server-user=<agent-name>
```

For the Hermes agents (leo, charlie, danny, cj, sam) this is a straight copy
of the existing per-agent secret pattern. Two newer identities need this set
up fresh, not copied from an existing agent config:

- **`claude-rp`** - interactive Claude Code sessions on rainbow-planet. Needs
  `BEADS_DOLT_PASSWORD`/`BEADS_DOLT_SERVER_TLS`/`BEADS_ACTOR=claude-rp`
  exported somewhere that's live for every interactive session on this
  laptop (shell env, not yet decided exactly where).
- **`mr-c`** - the Buzz-side Claude Code agent (`~/.buzz`). Currently shares
  the embedded DB; this is where it switches to the central server with its
  own real identity instead.

Verify with `bd dolt test`, then `bd ready`/`bd list` and confirm the
existing issues/epics/history are all present and unchanged.

## 5. Verify, then decommission the embedded copy

- [ ] Two separate clients see the same records.
- [ ] A write from one is visible from the other without manual sync.
- [ ] `bd dolt status` on each client confirms server mode, not embedded.
- [ ] Only after all of the above: the old `.beads/embeddeddolt/` on
      whichever machine hosted it can be removed - keep the tarball from
      step 1 regardless.

## 6. Wire the restic backup into verification

`dolt-beads-backup.service`/timer is already deployed as part of the Nix
module (01:00 daily, before this host's own 02:00 restic run). After step 3,
manually run `systemctl start dolt-beads-backup` once and confirm
`/var/backup/dolt-beads` has real content before trusting the automated
schedule.
