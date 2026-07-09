{ fetchurl
, lib
, makeWrapper
, puppeteerExecutablePath ? null
, stdenv
}:

stdenv.mkDerivation rec {
  pname = "oh-my-pi";
  version = "16.3.12";

  src = fetchurl {
    url = "https://github.com/can1357/oh-my-pi/releases/download/v${version}/omp-linux-x64";
    hash = "sha256-x8sBV2xpbZa5bCHWkegpRRGb87u3MW4+ifxbF+IH27c=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontUnpack = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 "$src" "$out/lib/oh-my-pi/omp-linux-x64"
    makeWrapperArgs=(
      --add-flags "--argv0"
      --add-flags "$out/lib/oh-my-pi/omp-linux-x64"
      --add-flags "$out/lib/oh-my-pi/omp-linux-x64"
    )
    ${lib.optionalString (puppeteerExecutablePath != null) ''
      makeWrapperArgs+=(
        --set PUPPETEER_EXECUTABLE_PATH ${lib.escapeShellArg puppeteerExecutablePath}
      )
    ''}
    makeWrapper "${stdenv.cc.libc}/lib/ld-linux-x86-64.so.2" "$out/bin/omp" "''${makeWrapperArgs[@]}"

    runHook postInstall
  '';

  meta = {
    description = "AI coding agent for the terminal";
    homepage = "https://github.com/can1357/oh-my-pi";
    license = lib.licenses.mit;
    mainProgram = "omp";
    platforms = [ "x86_64-linux" ];
  };
}
