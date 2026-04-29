class Skynet < Formula
  desc "S.K.Y.N.E.T. — System for Knowledge, Yielding Neural Engagement & Tasks"
  homepage "https://github.com/Parthee-Vijaya/skynet"
  url "https://github.com/Parthee-Vijaya/skynet/archive/refs/tags/v0.1.1.tar.gz"
  sha256 "ee126dc7ea686501f4d026d9c2812ff3a3867ecd9b07360ecc87abb904cbfd33"
  license "MIT"
  head "https://github.com/Parthee-Vijaya/skynet.git", branch: "main"

  depends_on "git"
  depends_on :macos
  depends_on "node"

  def install
    libexec.install Dir["*", ".npmrc"]

    cd libexec do
      # NB: std_npm_args bruges normalt til at publicere én npm-pakke;
      # vi bygger en monorepo med workspaces in-place og kan derfor ikke
      # bruge det her. FormulaAudit/StdNpmArgs-warningen kan ignoreres.
      system "npm", "install", "--legacy-peer-deps", "--no-audit", "--no-fund"
      system "npm", "run", "build:daemon"
      system "npm", "run", "build", "--workspace=@skynet/portal"
    end

    node_bin = Formula["node"].opt_bin
    (bin/"skynet").write <<~SH
      #!/bin/bash
      export PATH="#{node_bin}:$PATH"
      exec "#{node_bin}/node" "#{libexec}/packages/cli/dist/index.js" "$@"
    SH
    chmod 0755, bin/"skynet"

    (bin/"skynet-portal").write <<~SH
      #!/bin/bash
      export PATH="#{node_bin}:$PATH"
      cd "#{libexec}/packages/portal" && exec "#{node_bin}/npm" run start
    SH
    chmod 0755, bin/"skynet-portal"

    (bin/"skynet-daemon").write <<~SH
      #!/bin/bash
      export PATH="#{node_bin}:$PATH"
      cd "#{libexec}" && exec "#{node_bin}/npm" run start
    SH
    chmod 0755, bin/"skynet-daemon"

    (bin/"skynet-uninstall").write <<~'SH'
      #!/usr/bin/env bash
      # Komplet afinstallation af S.K.Y.N.E.T.
      # Re-exec'er fra /tmp saa scriptet ikke forsvinder under brew uninstall.
      set -u

      if [[ "${SKYNET_UNINSTALL_REEXEC:-0}" != "1" ]]; then
        TMPCOPY="$(mktemp /tmp/skynet-uninstall.XXXXXX)"
        cp "$0" "$TMPCOPY"
        chmod +x "$TMPCOPY"
        SKYNET_UNINSTALL_REEXEC=1 exec "$TMPCOPY" "$@"
      fi

      info() { printf '\033[0;34m▌\033[0m %s\n' "$*"; }
      ok()   { printf '\033[0;32m✓\033[0m %s\n' "$*"; }
      warn() { printf '\033[0;33m⚠\033[0m %s\n' "$*"; }
      step() { printf '\n\033[0;34m━━━ %s ━━━\033[0m\n' "$*"; }

      DOMAIN="gui/$(id -u)"
      LAUNCH_AGENTS=(com.skynet.portal com.skynet.daemon com.paseo.daemon com.jarvis.dashboard)

      step "Stopper services"
      brew services stop skynet >/dev/null 2>&1 && ok "brew service stoppet" || true
      for L in "${LAUNCH_AGENTS[@]}"; do
        if launchctl print "$DOMAIN/$L" >/dev/null 2>&1; then
          launchctl bootout "$DOMAIN/$L" 2>/dev/null && ok "$L stoppet" || warn "$L kunne ikke stoppes"
        fi
      done

      step "Fjerner LaunchAgent-plists"
      for L in "${LAUNCH_AGENTS[@]}"; do
        PLIST="$HOME/Library/LaunchAgents/${L}.plist"
        if [[ -f "$PLIST" ]]; then
          rm -f "$PLIST" && ok "fjernet $PLIST"
        fi
      done

      step "Fjerner data og logs"
      if [[ -d "$HOME/skynet" ]]; then
        rm -rf "$HOME/skynet" && ok "fjernet ~/skynet"
      fi
      rm -f "$HOME/Library/Logs/"skynet-*.log "$HOME/Library/Logs/"skynet.{out,err}.log 2>/dev/null
      rm -f "$HOME/Library/Logs/"paseo.{out,err}.log 2>/dev/null
      rm -f "$HOME/Library/Logs/"jarvis.{out,err}.log 2>/dev/null
      ok "logs ryddet"

      step "Fjerner global Paseo CLI"
      if command -v paseo >/dev/null 2>&1; then
        npm uninstall -g @getpaseo/cli >/dev/null 2>&1 && ok "paseo CLI fjernet" || warn "paseo CLI kunne ikke fjernes"
      else
        ok "paseo CLI ikke installeret"
      fi

      step "Fjerner brew-installation"
      if brew list skynet >/dev/null 2>&1; then
        brew uninstall skynet && ok "brew uninstall OK" || warn "brew uninstall fejlede"
      fi
      if brew tap | grep -qi 'parthee-vijaya/skynet'; then
        brew untap Parthee-Vijaya/skynet 2>/dev/null && ok "tap fjernet"
      fi

      step "Faerdig"
      ok "Skynet er afinstalleret"
      printf '\n\033[2mHvis du vil have brew til ogsaa at fjerne ubrugte dependencies:\n  brew autoremove\033[0m\n\n'

      rm -f "$0"
    SH
    chmod 0755, bin/"skynet-uninstall"
  end

  service do
    run [opt_bin/"skynet-daemon"]
    keep_alive true
    log_path var/"log/skynet-daemon.out.log"
    error_log_path var/"log/skynet-daemon.err.log"
    environment_variables NODE_ENV: "production"
  end

  def caveats
    <<~EOS
      Skynet er installeret under:
        #{opt_libexec}

      Start daemon (port 6767) automatisk ved login:
        brew services start skynet

      Start portal (port 3100) i baggrunden:
        brew services start skynet  # daemon
        nohup skynet-portal > ~/Library/Logs/skynet-portal.log 2>&1 &

      Eller kør CLI manuelt:
        skynet --help

      Opdater til nyeste version:
        brew update && brew upgrade skynet

      Afinstaller alt (services, plists, repo, logs, brew):
        skynet-uninstall

      Hvis du vil have den fulde LaunchAgent-opsætning fra repoet
      (portal + daemon + Paseo + HUD), kør den klassiske installer:
        bash #{opt_libexec}/scripts/install.sh
    EOS
  end

  test do
    assert_path_exists bin/"skynet"
    assert_predicate bin/"skynet", :executable?
  end
end
