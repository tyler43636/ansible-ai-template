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
          ompVersion = "v18.3.0";
          ompPlatform =
            if system == "x86_64-linux" then "linux-x64"
            else if system == "aarch64-linux" then "linux-arm64"
            else if system == "x86_64-darwin" then "darwin-x64"
            else if system == "aarch64-darwin" then "darwin-arm64"
            else throw "Unsupported system: ${system}";
          ompHash =
            if system == "x86_64-linux" then "1hsbp620lx80rhdn6246y8fjj7wgahpx8y4wxfbfb5pymwlsmzfj"
            else if system == "aarch64-linux" then "0dy6fzjgn1pyivdw8wj1rrs3b5d122h1dbkdjphzx8hp9r4rryxx"
            else if system == "x86_64-darwin" then "1bqv0agclqpb08x6n05191vhmw7bw3q2bfa7h80pxpnw1s74jx5y"
            else if system == "aarch64-darwin" then "1p1mijmvgdf4d7d1ssgfk7c9g8hjb4xv20fripabwij1y88v87yn"
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
