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
          ompVersion = "v18.2.8";
          ompPlatform =
            if system == "x86_64-linux" then "linux-x64"
            else if system == "aarch64-linux" then "linux-arm64"
            else if system == "x86_64-darwin" then "darwin-x64"
            else if system == "aarch64-darwin" then "darwin-arm64"
            else throw "Unsupported system: ${system}";
          ompHash =
            if system == "x86_64-linux" then "0r8xidnkmnczi61jg5lrhdj506hk3jvagynp4rfzv1wx6fkivh5h"
            else if system == "aarch64-linux" then "01jqkvad4hdk2k2bplha4ag840f4ccsd1zp9hc3amk4m7kj67am9"
            else if system == "x86_64-darwin" then "0hfsl493mk1jzpbr14yljc9310i8pdgak6y1dqk9ph6xmjxw51dk"
            else if system == "aarch64-darwin" then "11spkqaj5fgfpiz9zn79i1wc1r164342jkz7rcddwq3gzskk93fg"
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
              "ansible-core" = pyPrev."ansible-core".overrideAttrs (old: {
                propagatedBuildInputs = pkgs.lib.filter
                  (package: package != pyPrev.ansible)
                  old.propagatedBuildInputs;
              });
              # ansible-compat relies on jsonschema through the removed meta
              # distribution instead of declaring it directly.
              "ansible-compat" = pyPrev."ansible-compat".overrideAttrs (old: {
                propagatedBuildInputs = old.propagatedBuildInputs ++ [ pyFinal.jsonschema ];
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
              (python3.withPackages (ps: with ps; [
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
