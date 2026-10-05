# Danny's 6am daily report (hermes-agent-fleet-plan issue 41). Cron job
# definitions are pure runtime CLI/API state in hermes-agent - confirmed
# directly against the locked source (cron/jobs.py, hermes_cli/cron.py):
# no declarative Nix option exists for this, not even the free-form
# settings.yaml blob. `hermes cron create` is a direct local-state write
# (cron.jobs.create_job via tools.cronjob_tools, not a gateway API call -
# confirmed _cron_api() is a plain Python import, and cron_create only
# *warns*, doesn't fail, if the gateway isn't running), so registration
# can run before hermes-agent.service starts, same as Charlie's
# tea-login-setup.
#
# The 6am trigger IS hermes-agent's own internal scheduler, not a
# separate systemd.timer - confirmed directly against the live CLI
# (`hermes cron --help`/`cron run --help`): `cron run <job_id>` only
# "runs a job on the next scheduler TICK" - it marks a job due and
# depends on the gateway's own always-on ticker (running inside
# hermes-agent.service) to actually fire it; `cron tick` itself yields
# to that same live gateway if one owns the runtime lock
# (CronTickYielded, cron/scheduler.py). There is no code path that
# executes a job without that gateway process, so a systemd.timer
# layered on top would just depend on the exact same process this
# job's own schedule already depends on, while adding a paused-job
# gate `cron run` can't bypass (confirmed live: a paused job refuses
# `cron run` outright - "Job is paused/disabled; resume it before
# running"). Scheduling reliability here is "is hermes-agent.service
# up", already systemd-supervised; timezone resolution is the
# container's own `time.timeZone` (hostTimeZone, set fleet-wide in
# container-builder.nix), already confirmed correct. So: register the
# job ACTIVE (no --paused) with its real cron schedule and let the
# gateway's own ticker fire it - one scheduling authority, just not
# the one originally assumed.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  hermesBin = "${config.services.hermes-agent.package}/bin/hermes";
  jobName = "daily-social-report";
  hermesHome = "${config.services.hermes-agent.stateDir}/.hermes";
in
{
  systemd.services.daily-social-report-cron-setup = {
    description = "Register Danny's daily-social-report cron job (one-time)";
    wantedBy = [ "multi-user.target" ];
    before = [ "hermes-agent.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = config.services.hermes-agent.user;
      Group = config.services.hermes-agent.group;
      Environment = "HERMES_HOME=${hermesHome}";
    };
    # Skip-if-present (tea-login-setup's own convention), not
    # remove-then-create: a plain `grep` for the job name against
    # `cron list --all`'s pretty-printed table missed an already-registered
    # job once during this feature's own testing, leaving a duplicate - but
    # the fix for that is a precise field match, not discarding the job's
    # id/run-history on every redeploy (this container restarts for reasons
    # that have nothing to do with this job's own definition, e.g. a shared
    # container-builder.nix change). Match on the exact `Name:` field
    # instead of a loose substring, the same parse already proven reliable
    # for by-name lookup during that same testing.
    script = ''
      set -euo pipefail
      existing_ids=$(${hermesBin} cron list --all 2>/dev/null | ${pkgs.gawk}/bin/awk -v name="${jobName}" '
        /^  [0-9a-f]+ \[/ { id = $1 }
        $1 == "Name:" && $2 == name { print id }
      ')
      if [ -n "$existing_ids" ]; then
        exit 0
      fi
      ${hermesBin} cron create "0 6 * * *" \
        "Generate and publish today's social report per the daily-social-report skill." \
        --name ${jobName} \
        --skill ${jobName} \
        --deliver buzz
    '';
  };
}
