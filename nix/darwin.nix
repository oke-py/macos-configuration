{
  pkgs,
  lib,
  username,
  ...
}:

let
  # Pin the official macOS binary until nixpkgs provides this release.
  nodejs24 = pkgs.stdenvNoCC.mkDerivation {
    pname = "nodejs";
    version = "24.22.1";

    src = pkgs.fetchurl {
      url = "https://nodejs.org/dist/v24.22.1/node-v24.22.1-darwin-arm64.tar.xz";
      sha256 = "654ba79de6155647e22321932b45f2a1ccb705976cc337c9b8e278beb085a628";
    };

    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -R bin include lib share "$out/"
      runHook postInstall
    '';

    # Preserve the signed upstream binaries and npm's portable shebangs.
    dontFixup = true;
    meta.platforms = [ "aarch64-darwin" ];
  };
in
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "claude-code"
    ];

  system.primaryUser = username;
  system.stateVersion = 7;

  users.users.${username}.home = "/Users/${username}";

  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    claude-code
    codex
    curl
    fzf
    gh
    ghq
    git
    gnused
    gnutar
    jq
    nodejs24
    ripgrep
    starship
    tree
    uv
    wget
    yq
  ];

  system.defaults = {
    dock = {
      orientation = "right";
      minimize-to-application = true;
      show-recents = false;
    };

    finder = {
      AppleShowAllExtensions = true;
      NewWindowTarget = "Home";
      AppleShowAllFiles = true;
      FXPreferredViewStyle = "clmv";
    };

    screencapture = {
      type = "png";
      disable-shadow = true;
      location = "/Users/${username}/Pictures";
    };

    CustomUserPreferences = {
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
      };
      "com.apple.screencapture" = {
        name = "ss_";
      };
    };
  };
}
