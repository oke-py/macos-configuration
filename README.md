# ansible-osx

macOS configuration management using Nix, nix-darwin, and Home Manager.

## nix-darwin

This repository contains a nix-darwin + Home Manager configuration for `uranus`.

### prerequisite

Install Lix first. Lix provides the `nix` command and satisfies the Nix prerequisite for nix-darwin.

```bash
$ curl -sSf -L https://install.lix.systems/lix | sh -s -- install
```

After installation, open a new shell or load the Nix daemon profile.

```bash
$ exec $SHELL -l
```

If `nix` is still unavailable in the current shell, load the profile explicitly.

```bash
$ . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

Other installers, such as the official Nix installer or Determinate Nix Installer, should also work, but Lix is the documented default for this repository.

### bootstrap

Use `/etc/nix-darwin` only for the first nix-darwin bootstrap. The upstream Getting Started templates are alternatives; use `nix-darwin/master` here.

```bash
$ sudo mkdir -p /etc/nix-darwin
$ sudo chown $(id -nu):$(id -ng) /etc/nix-darwin
$ cd /etc/nix-darwin
$ nix flake init -t nix-darwin/master
$ sed -i '' "s/simple/$(scutil --get LocalHostName)/" flake.nix
$ nix flake lock
$ sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#$(scutil --get LocalHostName)
```

After the bootstrap succeeds, apply the repository-managed configuration.

```bash
$ cd ~/src/github.com/oke-py/ansible-osx
$ sudo /run/current-system/sw/bin/darwin-rebuild switch --flake .#uranus
```

### apply changes

```bash
$ sudo /run/current-system/sw/bin/darwin-rebuild switch --flake .#uranus
```

### update inputs

```bash
$ nix flake update
$ sudo /run/current-system/sw/bin/darwin-rebuild switch --flake .#uranus
```

### managed areas

| Area | Location | Notes |
| --- | --- | --- |
| CLI packages | `environment.systemPackages` in `nix/darwin.nix` | Command-line tools are installed from nixpkgs. |
| AI CLIs | `claude-code` and `codex` in `nix/darwin.nix` | Claude Code and Codex CLI are installed from nixpkgs. |
| Node.js | `nodejs24` in `nix/darwin.nix` | Official macOS ARM64 binary pinned to v24.22.1 with a SHA-256 checksum. |
| uv | `uvPinned` in `nix/darwin.nix` | Official macOS ARM64 binaries pinned to 0.13.5 with a SHA-256 checksum. |
| CLI CA certificates | `security.pki` in `nix/darwin.nix` | Filters roots associated with the eMudhra incident, including the AAA cross-signing path. Nix, curl, Git, and clients honoring `SSL_CERT_FILE` use this bundle. |
| macOS defaults | `system.defaults` in `nix/darwin.nix` | Dock, Finder, desktop services, and screenshot defaults are managed by nix-darwin. |
| zsh | `home.file.".zshrc"` in `nix/home.nix` | The zshrc content lives in `nix/zshrc`. |
| Git | `programs.git.settings` in `nix/home.nix` | Global Git configuration is managed by Home Manager. |
| npm | `home.file.".npmrc"` in `nix/home.nix` | npm supply-chain safeguards live in `nix/npmrc`. |
| SSH | `home.file.".ssh/config"` and `home.activation.createSshDirs` in `nix/home.nix` | SSH config lives in `nix/ssh_config` and uses the 1Password SSH agent. |
| Docker completion | `docker completion zsh` in `nix/zshrc` | Docker completion is loaded dynamically when the `docker` command is available. |

This repository used to manage macOS with Ansible and Homebrew. The Ansible implementation has been removed after reaching parity with the Nix configuration.

### eMudhra CA incident follow-up

After applying the configuration, run
`exec env -u __NIX_DARWIN_SET_ENVIRONMENT_DONE zsh -l` to reload the CA
environment variables even if the old Nix environment was already loaded.
The filtered bundle is at
`/etc/ssl/certs/ca-certificates.crt`; Nix also references it in its configuration
so it does not depend on environment variables surviving sudo.

This does not modify Apple's `/etc/ssl/cert.pem`, update macOS or browser trust
stores, or repair CA bundles embedded in other applications and containers.
See [Apple's guidance](https://support.apple.com/en-ca/149555) for macOS tools
that use `/etc/ssl/cert.pem`.

Updating uv does not update existing Python environments. Upgrade their certifi
to 2026.10.19 or later and pip to a release with the fixed vendored certifi
(26.2.2 or later). For uv-managed Python, use `uv python upgrade` after updating
uv, and check existing virtual environments separately. See the
[uv release notes](https://github.com/astral-sh/uv/releases/tag/0.13.5) and
[Nix mitigation tracker](https://github.com/NixOS/nixpkgs/issues/576485).
