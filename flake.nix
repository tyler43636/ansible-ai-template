{
  description = "Ansible AI template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor = system: import nixpkgs { inherit system; config.allowUnfree = true; };
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = pkgsFor system;
          ompVersion = "v18.22.2";
          ompPlatform =
            if system == "x86_64-linux" then "linux-x64"
            else if system == "aarch64-linux" then "linux-arm64"
            else if system == "x86_64-darwin" then "darwin-x64"
            else if system == "aarch64-darwin" then "darwin-arm64"
            else throw "Unsupported system: ${system}";
          ompHash =
            if system == "x86_64-linux" then "1d85575s9dnw0qrdp039mfxqzkxkxpbpprqipcj13ixrmp2r59l0"
            else if system == "aarch64-linux" then "1qh28n7j7h80x7m691crh5ar9n4ykxzl8c99l60iqgyp0jx81a42"
            else if system == "x86_64-darwin" then "0fz4x8d1mqxs9nxfw9bdck2z21f6g30566ldqidagq53d5nr6d7m"
            else if system == "aarch64-darwin" then "0n0ljs5i5gmi0ji77c3rfg9ij42kywy7fskamyiayfz1ypwm68nh"
            else "";
          oh-my-pi = pkgs.stdenv.mkDerivation {
            pname = "oh-my-pi";
            nativeBuildInputs = pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.patchelf ];
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
              # Only set the interpreter: omp needs nothing beyond glibc, and
              # --set-rpath corrupts the Bun-compiled binary (segfaults since v18.12).
              if [ -f "${pkgs.stdenv.cc}/nix-support/dynamic-linker" ]; then
                patchelf --set-interpreter "$(cat ${pkgs.stdenv.cc}/nix-support/dynamic-linker)" \
                         $out/bin/omp
              fi
            '';
          };
          omp-wrapped = pkgs.writeShellScriptBin "omp" ''
            args=("--plugin-dir=${self}/.omp")
            if [ -d "$PWD/.omp" ]; then
              args+=("--plugin-dir=$PWD/.omp")
            fi
            exec ${oh-my-pi}/bin/omp "''${args[@]}" "$@"
          '';
          ansible-init = pkgs.python3Packages.buildPythonApplication {
            pname = "ansible-init";
            version = "0.1.0";
            src = ./cli;
            format = "pyproject";
            build-system = [ pkgs.python3Packages.setuptools ];
            propagatedBuildInputs = [ pkgs.python3Packages.jinja2 ];
          };
          ansible-init-wrapped = pkgs.writeShellScriptBin "ansible-init" ''
            export ANSIBLE_INIT_TEMPLATE_DIR="${self}/templates"
            exec ${ansible-init}/bin/ansible-init "$@"
          '';
          molecule-init-wrapped = pkgs.writeShellScriptBin "molecule-init" ''
            export ANSIBLE_INIT_TEMPLATE_DIR="${self}/templates"
            exec ${ansible-init}/bin/molecule-init "$@"
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
              docker-client
              openssh
              libvirt
              vault
              (terraform.withPlugins (p: [ p.dmacvicar_libvirt ]))
              terraform-ls
              tflint
              omp-wrapped
              molecule-init-wrapped
              ansible-init-wrapped
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
