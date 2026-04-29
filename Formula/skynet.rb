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
