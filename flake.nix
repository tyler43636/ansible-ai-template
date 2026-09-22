{
  description = "Ansible AI template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor = system: import nixpkgs { inherit system; };
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = pkgsFor system;
          ompVersion = "v17.2.9";
          ompPlatform =
            if system == "x86_64-linux" then "linux-x64"
            else if system == "aarch64-linux" then "linux-arm64"
            else if system == "x86_64-darwin" then "darwin-x64"
            else if system == "aarch64-darwin" then "darwin-arm64"
            else throw "Unsupported system: ${system}";
          ompHash =
            if system == "x86_64-linux" then "0ax00a7mx7qbi1l38sgkxsiw00hxwcq3diy8b8dc2izkn8rynyjg"
            else if system == "aarch64-linux" then "10z2jxgghyx0n9zm34966pya0ljjq6ymhhdacn5gc55ydnlv1i73"
            else if system == "x86_64-darwin" then "0izkqmlvrah8clwv0yv86iakmlbapdcr7zv17bgvdzk87a4nzhrm"
            else if system == "aarch64-darwin" then "061ilqw1idjcj4sdb4zy34iriv9cqbd9q30sm2sji16scp24971z"
            else "";
          oh-my-pi = pkgs.stdenv.mkDerivation {
            pname = "oh-my-pi";
            nativeBuildInputs = pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.patchelf ];
            buildInputs = pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.stdenv.cc.cc.lib ];
            version = ompVersion;
            src = pkgs.fetchurl {
              url = "https://github.com/can1357/oh-my-pi/releases/download/${ompVersion}/omp-${ompPlatform}";
              sha256 = ompHash;
            };
            dontUnpack = true;
            dontStrip = true;
            installPhase = ''
              mkdir -p $out/bin
              cp $src $out/bin/omp
              chmod u+wx $out/bin/omp
              if [ -f "${pkgs.stdenv.cc}/nix-support/dynamic-linker" ]; then
                patchelf --set-interpreter "$(cat ${pkgs.stdenv.cc}/nix-support/dynamic-linker)" \
                         --set-rpath "${pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]}" \
                         $out/bin/omp
              fi
            '';
          };
          omp-wrapped = pkgs.writeShellScriptBin "omp" ''
            exec ${oh-my-pi}/bin/omp --plugin-dir="${self}/.omp" "$@"
          '';
          # ansible-core currently propagates the complete `ansible` Python
          # distribution. That reverses the normal dependency direction and
          # makes tools discover immutable bundled collections in addition to
          # the writable Galaxy location. Remove that propagation so Galaxy is
          # the sole collection installation path for a consumer project.
          python = pkgs.python3.override {
            packageOverrides = pyFinal: pyPrev: {
              "ansible-core" = pyPrev."ansible-core".overridePythonAttrs (old: {
                dependencies = pkgs.lib.filter
                  (package: package != pyPrev.ansible)
                  (old.dependencies or [ ]);
                propagatedBuildInputs = pkgs.lib.filter
                  (package: package != pyPrev.ansible)
                  (old.propagatedBuildInputs or [ ]);
              });
              # ansible-compat relies on jsonschema through the removed meta
              # distribution instead of declaring it directly.
              "ansible-compat" = pyPrev."ansible-compat".overrideAttrs (old: {
                propagatedBuildInputs = old.propagatedBuildInputs ++ [ pyFinal.jsonschema ];
              });
              yamllint = pyPrev.yamllint.overridePythonAttrs (old: rec {
                version = "1.38.0";
                src = pkgs.fetchFromGitHub {
                  owner = "adrienverge";
                  repo = "yamllint";
                  rev = "v${version}";
                  hash = "sha256-4H8tbn2TRzTGIXmP9Hnmc93rGSLsWh5A5R9KAIz0mKM=";
                };
              });
            };
          };
          ansible = python.pkgs.toPythonApplication python.pkgs."ansible-core";
          ansible-lint = pkgs.callPackage
            (pkgs.path + "/pkgs/by-name/an/ansible-lint/package.nix")
            {
              python3Packages = python.pkgs;
              inherit ansible;
            };
          molecule = python.pkgs.molecule;
          ansible-navigator = pkgs.callPackage
            (pkgs.path + "/pkgs/by-name/an/ansible-navigator/package.nix")
            {
              inherit ansible-lint;
            };
        in
        {
          default = pkgs.mkShell {
            name = "ansible-dev";
            packages = with pkgs; [
              ansible
              ansible-lint
              ansible-language-server
              ansible-navigator
              ansible-builder
              nodejs
              molecule
              pre-commit
              nixd
              yaml-language-server
              bash-language-server
              marksman
              pyright
              ruff
              (python.withPackages (ps: with ps; [
                requests
                pytz
                docker
                pytest-ansible
                molecule-plugins
                hvac
              ]))
              jq
              yq-go
              tree
              socat
              imagemagick
              omp-wrapped
              just
              shellcheck
              statix
            ];

            ANSIBLE_LOCALHOST_WARNING = "false";

            shellHook = ''
              if [ -z "''${PUPPETEER_EXECUTABLE_PATH:-}" ] && command -v chromium >/dev/null; then
                export PUPPETEER_EXECUTABLE_PATH="$(command -v chromium)"
              fi
            '';
          };
        }
      );
    };
}
