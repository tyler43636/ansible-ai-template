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
          ompVersion = "v18.1.15";
          ompPlatform =
            if system == "x86_64-linux" then "linux-x64"
            else if system == "aarch64-linux" then "linux-arm64"
            else if system == "x86_64-darwin" then "darwin-x64"
            else if system == "aarch64-darwin" then "darwin-arm64"
            else throw "Unsupported system: ${system}";
          ompHash =
            if system == "x86_64-linux" then "1p4s2h9ni0ynb31hdq3sjzjxkl11m6kpfihv953sqcmv3yj1hxbl"
            else if system == "aarch64-linux" then "12b1azq8dfv1aqlyz1v3yd8mbff7a6n12mx0ccxl2xmvsk64449f"
            else if system == "x86_64-darwin" then "1p5lkfskj23kw7k8x2cdjp1aa14j8p4i7c21kw74bf4m0x0j5p3r"
            else if system == "aarch64-darwin" then "1gp84kaga6njqg806fspiqbxc0zgqf03v57ac09xaw3l5wk91q71"
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
              ]))
              jq
              yq-go
              tree
              socat
              imagemagick
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
