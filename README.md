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
| macOS defaults | `system.defaults` in `nix/darwin.nix` | Dock, Finder, desktop services, and screenshot defaults are managed by nix-darwin. |
| zsh | `home.file.".zshrc"` in `nix/home.nix` | The zshrc content lives in `nix/zshrc`. |
| Git | `programs.git.settings` in `nix/home.nix` | Global Git configuration is managed by Home Manager. |
| npm | `home.file.".npmrc"` in `nix/home.nix` | npm supply-chain safeguards live in `nix/npmrc`. |
| SSH | `home.file.".ssh/config"` and `home.activation.createSshDirs` in `nix/home.nix` | SSH config lives in `nix/ssh_config` and uses the 1Password SSH agent. |
| Docker completion | `docker completion zsh` in `nix/zshrc` | Docker completion is loaded dynamically when the `docker` command is available. |

This repository used to manage macOS with Ansible and Homebrew. The Ansible implementation has been removed after reaching parity with the Nix configuration.

### manual cleanup

After applying the Nix configuration, remove old mise state if it is no longer needed.

```bash
$ rm -rf ~/.config/mise ~/.local/share/mise
```

After verifying the Nix-managed Claude Code and Codex CLI installations, remove old manual installs if they are no longer needed.

Homebrew is no longer on `PATH`, but the previous formulae may still exist under `/opt/homebrew`. Most leaves are now managed by Nix. `go`, `k6`, and `kubectl` are intentionally not migrated because they are not currently needed.

Review the remaining Homebrew leaves before uninstalling them.

```bash
$ /opt/homebrew/bin/brew leaves
```

If the list only contains replaced or unused tools, remove the old formulae and their unused dependencies.

```bash
$ /opt/homebrew/bin/brew uninstall curl fzf gh ghq git gnu-sed gnu-tar go jq k6 libomp mise starship tree uv wget yq
$ /opt/homebrew/bin/brew autoremove
$ /opt/homebrew/bin/brew cleanup
```

Keep Homebrew itself installed until GUI application management is revisited.
