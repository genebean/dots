# Gitdeck on nixnuc

Gitdeck uses the published `ghcr.io/debba/gitdeck:v1.0.10` image pinned in
[`containers/gitdeck.nix`](containers/gitdeck.nix). Podman pulls it on first
start and runs as root, following the other OCI containers on this host.
Inside the image, the entrypoint fixes data directory ownership and then
starts the Node server as the unprivileged `node` user.

## One-time GitHub setup

1. Create a **GitHub OAuth App** under your account's Developer settings.
   Set its homepage and required callback URL to
   `http://192.168.20.190:8765` (Gitdeck's Device Flow does not use the
   callback). Enable **Device Flow** on the app's settings page.
2. The app's public Client ID is already declared in nixnuc's Nix
   configuration as `genebean.gitdeck.githubClientId`; deploy the host
   configuration to start Gitdeck. No file needs to be installed manually on
   nixnuc. A client **secret** is not needed; the OAuth access token is created
   by Gitdeck at login and persisted in the backed-up data directory.
3. Open `http://192.168.20.190:8765` from the LAN, or over Tailscale using the
   already advertised `192.168.20.0/22` subnet route. Follow Gitdeck's device
   sign-in prompt and review the scopes requested by upstream. Its defaults
   include `repo`, `read:org`, `project`, `read:user`, and `user:email` to
   support private repositories, notifications, and Projects. A narrower
   `GITHUB_OAUTH_SCOPES` value could be added declaratively to the container
   environment, but test Inbox and Board after changing it.

Gitdeck's browser login is **not an access-control layer for this shared
server**: its API uses the token stored on the server. The container port
listens on all host interfaces, like the other OCI containers. This deployment
does not add a reverse proxy route. Only use this URL on the trusted LAN or via
the tailnet subnet route; add an authenticated proxy before giving access to
other networks. The optional OpenAI digest key is deliberately absent.

## Maintenance

- Check `systemctl status podman-gitdeck.service` and
  `journalctl -u podman-gitdeck.service` for startup problems.
- Renovate tracks the literal `image = "ghcr.io/debba/gitdeck:v1.0.10";` in
  `containers/gitdeck.nix` through the repo's OCI image rule. Review its image
  update PRs and redeploy to pull the new tag.
- OAuth tokens and Gitdeck snapshots live at `/var/lib/gitdeck/data` on the
  host; the existing encrypted daily restic backup includes that directory.
  Restore it with its original permissions before starting the container.
  Revoking the OAuth App in GitHub and removing its stored token from this
  directory forces a fresh sign-in.
- Codeberg can be added from Gitdeck's account picker with a Forgejo token;
  that token is also stored in the backed-up data directory. Do not put it in
  Nix source. Gitdeck v1.0.10's account picker does not yet provide an instance
  URL field for self-hosted Forgejo.
