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
          ansibleOmpSkills = pkgs.runCommand "ansible-omp-skills" { } ''
            mkdir -p "$out"
            cp -R ${./.pi/skills/ansible} "$out/ansible"
          '';
          oh-my-pi = pkgs.callPackage ./pkgs/oh-my-pi { };
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
            ];

            ANSIBLE_LOCALHOST_WARNING = "false";
            OMP_SKILLS = "${ansibleOmpSkills}";

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
