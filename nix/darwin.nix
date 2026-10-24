{
  config,
  pkgs,
  lib,
  username,
  ...
}:

let
  caBundle = "/etc/ssl/certs/ca-certificates.crt";
  filteredCacert = pkgs.cacert.override {
    blacklist = config.security.pki.caCertificateBlacklist;
  };

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

  # uv >= 0.13.4 removes the compromised emSign root from its bundled CA store.
  uvPinned = pkgs.stdenvNoCC.mkDerivation {
    pname = "uv";
    version = "0.13.5";

    src = pkgs.fetchurl {
      url = "https://github.com/astral-sh/uv/releases/download/0.13.5/uv-aarch64-apple-darwin.tar.gz";
      sha256 = "743f85035a1996ecb350659e01cd9faea9709829be09b1b4b03c73eaf3c9cd73";
    };

    installPhase = ''
      runHook preInstall
      install -Dm755 uv "$out/bin/uv"
      install -Dm755 uvx "$out/bin/uvx"
      runHook postInstall
    '';

    dontFixup = true;
    meta.platforms = [ "aarch64-darwin" ];
  };
in
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Keep Nix on the filtered bundle even when sudo clears the environment.
  nix.settings.ssl-cert-file = caBundle;

  # Match the upstream nix-darwin mitigation for CVE-2026-111943.
  # AAA also cross-signed the compromised intermediates.
  security.pki.caCertificateBlacklist = [
    "Comodo AAA Services root"
  ]
  ++ lib.optionals (lib.versionOlder pkgs.cacert.version "3.131.1") [
    "emSign ECC Root CA - G3"
    "emSign Root CA - C1"
    "emSign ECC Root CA - C3"
  ];

  # Omit distrusted roots entirely, including for clients that ignore OpenSSL's
  # auxiliary trust/reject metadata in BEGIN TRUSTED CERTIFICATE blocks.
  security.pki.certificateFiles = lib.mkForce [
    "${filteredCacert}/etc/ssl/certs/ca-no-trust-rules-bundle.crt"
  ];

  # CLI clients must use the filtered bundle rather than their build-time CA file.
  environment.variables = {
    SSL_CERT_FILE = caBundle;
    CURL_CA_BUNDLE = caBundle;
    GIT_SSL_CAINFO = caBundle;
  };

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
    uvPinned
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
