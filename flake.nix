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
          ompVersion = "v16.3.14";
          ompPlatform =
            if system == "x86_64-linux" then "linux-x64"
            else if system == "aarch64-linux" then "linux-arm64"
            else if system == "x86_64-darwin" then "darwin-x64"
            else if system == "aarch64-darwin" then "darwin-arm64"
            else throw "Unsupported system: ${system}";
          ompHash =
            if system == "x86_64-linux" then "16cmngfi3zms5qc42lg7jj5dlydw6fq4si9ryj0mnjs9hbyf6z4b"
            else if system == "aarch64-linux" then "103qpyc5pc78ympzsz4awh8zjqcbx8f6yxhcwhv1ljksy744k06f"
            else if system == "x86_64-darwin" then "0bn0dkwgdan1y0pw8fnnmh30bvyqqha4g0lwa7b67lbscldaaild"
            else if system == "aarch64-darwin" then "0x1x5s1apm2b1qnwp1qcna7f6f03z7w9nsjd0ix33mj0318mgmiv"
            else "";
          oh-my-pi = pkgs.stdenv.mkDerivation {
            pname = "oh-my-pi";
            buildInputs = [ pkgs.stdenv.cc.cc.lib pkgs.makeWrapper ];
            version = ompVersion;
            src = pkgs.fetchurl {
              url = "https://github.com/can1357/oh-my-pi/releases/download/${ompVersion}/omp-${ompPlatform}";
              sha256 = ompHash;
            };
            dontUnpack = true;
            dontStrip = true;
            installPhase = ''
              mkdir -p $out/bin $out/libexec
              cp $src $out/libexec/omp-unpatched
              chmod +x $out/libexec/omp-unpatched

              cat > $out/bin/omp <<EOF
              #!/bin/sh
              export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:\$LD_LIBRARY_PATH"
              exec "$(cat ${pkgs.stdenv.cc}/nix-support/dynamic-linker)" $out/libexec/omp-unpatched "\$@"
              EOF
              chmod +x $out/bin/omp
            '';
          };
        in
        {
          default = pkgs.mkShell {
            name = "ansible-dev";
            packages = with pkgs; [
              ansible
              ansible-lint
              ansible-language-server
              nodejs
              molecule
              pre-commit
              (python3.withPackages (ps: with ps; [
                requests
                pytz
                docker
              ]))
              jq
              yq-go
              tree
              socat
              imagemagick
              oh-my-pi
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
