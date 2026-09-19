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
          ompVersion = "v18.2.6";
          ompPlatform =
            if system == "x86_64-linux" then "linux-x64"
            else if system == "aarch64-linux" then "linux-arm64"
            else if system == "x86_64-darwin" then "darwin-x64"
            else if system == "aarch64-darwin" then "darwin-arm64"
            else throw "Unsupported system: ${system}";
          ompHash =
            if system == "x86_64-linux" then "18j7jbpqxbzii5yy1hrczc9z4lcxk71iw5bzw36dh8z8j665jf0g"
            else if system == "aarch64-linux" then "1r2pp6vaq2kwyjz4jpjd5yfq3s77hkzap6zabjmrjf8c0nz5q907"
            else if system == "x86_64-darwin" then "18wl3az7v1c8m7k73p7xvhxn9v12cd9kxfybwf5cdar6lc7q0n6m"
            else if system == "aarch64-darwin" then "0fjix7zdydqx0490924bl0iggaa0xb1351nah6kgzqbpsm0dm66l"
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
