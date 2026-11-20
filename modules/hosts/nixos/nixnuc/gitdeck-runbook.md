# Gitdeck on nixnuc

Gitdeck runs from an upstream Dockerfile pinned in
[`containers/gitdeck.nix`](containers/gitdeck.nix). The systemd service builds the
image on nixnuc if its versioned tag does not already exist; this can take a
few minutes on the first activation. Podman runs as root, following the other
OCI containers on this host. Inside the image, the entrypoint fixes data
directory ownership and then starts the Node server as the unprivileged `node`
user.

## One-time GitHub setup

1. Create a **GitHub OAuth App** under your account's Developer settings.
   Set its homepage and required callback URL to
   `http://192.168.20.190:8765` (Gitdeck's Device Flow does not use the
   callback). Enable **Device Flow** on the app's settings page.
2. On nixnuc, put the app's public Client ID in a root-owned environment file:

   ```sh
   sudo install -d -m 0755 /etc/gitdeck
   printf 'GITHUB_CLIENT_ID=%s\n' 'YOUR_CLIENT_ID' | sudo tee /etc/gitdeck/oauth.env >/dev/null
   sudo chmod 0600 /etc/gitdeck/oauth.env
   sudo systemctl start podman-gitdeck.service
   ```

   The container service is skipped until this file exists. A client **secret**
   is not needed. After changing the ID, restart `podman-gitdeck.service`.
3. Open `http://192.168.20.190:8765` from the LAN, or over Tailscale using the
   already advertised `192.168.20.0/22` subnet route. Follow Gitdeck's device
   sign-in prompt and review the scopes requested by upstream. Its defaults
   include `repo`, `read:org`, `project`, `read:user`, and `user:email` to
   support private repositories, notifications, and Projects. A narrower
   `GITHUB_OAUTH_SCOPES` value can be added to `oauth.env`, but test Inbox and
   Board after changing it.

Gitdeck's browser login is **not an access-control layer for this shared
server**: its API uses the token stored on the server. The container port is
bound to nixnuc's LAN address and is not forwarded by the Internet router.
Only use this URL on the trusted LAN or via the tailnet subnet route; add an
authenticated proxy before giving access to other networks. The optional
OpenAI digest key is deliberately absent.

## Maintenance

- Check `systemctl status gitdeck-build-image.service podman-gitdeck.service`
  and `journalctl -u podman-gitdeck.service` for startup problems.
- Update the version, revision, and fetched archive hash together in
  `containers/gitdeck.nix`. The changed image tag causes a rebuild before the
  container restarts. The source uses the archive for the exact upstream
  commit, rather than a mutable branch.
- OAuth tokens and Gitdeck snapshots live at `/var/lib/gitdeck/data` on the
  host; the existing encrypted daily restic backup includes that directory.
  Restore it with its original permissions before starting the container.
  Revoking the OAuth App in GitHub and removing its stored token from this
  directory forces a fresh sign-in.
- Forgejo can be added from Gitdeck's account picker with a Forgejo token;
  that token is also stored in the backed-up data directory. Do not put it in
  Nix source or the Gitdeck Client ID environment file.
