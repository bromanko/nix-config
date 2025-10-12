{
  lib,
  stdenv,
  makeWrapper,
  coreutils,
  gnugrep,
  gnused,
  systemd,
  bind,
}:

stdenv.mkDerivation {
  pname = "dev-vm-scripts";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [
    coreutils
    gnugrep
    gnused
    systemd
    bind
  ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    install -Dm755 allowlist-domain.sh $out/bin/allowlist-domain
    install -Dm755 lockdown-network.sh $out/bin/lockdown-network

    # Wrap scripts with PATH to required tools
    wrapProgram $out/bin/allowlist-domain \
      --prefix PATH : ${
        lib.makeBinPath [
          coreutils
          gnugrep
          gnused
          systemd
          bind
        ]
      }

    wrapProgram $out/bin/lockdown-network \
      --prefix PATH : ${
        lib.makeBinPath [
          coreutils
          gnugrep
          gnused
          systemd
          bind
        ]
      }

    runHook postInstall
  '';

  meta = with lib; {
    description = "Utility scripts for managing Lima dev VM";
    maintainers = [ maintainers.bromanko or "bromanko" ];
    platforms = platforms.linux;
  };
}
