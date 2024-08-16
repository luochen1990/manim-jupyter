{
  description = "A Python development environment with poetry";

  inputs = {
    nixpkgs.url = "nixpkgs";
  };

  outputs = { self, nixpkgs }:
  let
    supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    eachSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f rec {
      inherit system;
      pkgs = import nixpkgs { inherit system; };
      python = pkgs.python310; #TODO: change to the version you want. e.g. `pkgs.python39` for python3.9;
      # or change to `pkgs.python310.withPackages (p: [])` if you need more python packages in nixpkgs
      pyver = python.version;
    });
  in
  {
    # use them via `nix develop .#xxx` or `direnv allow`
    devShells = eachSystem ({pkgs, python, ...}: rec {
      default = poetry;

      poetry = pkgs.mkShell {
        buildInputs = [
          python
          pkgs.poetry
        ];

        shellHook = ''
          export PATH=$(poetry env info --path)/bin:$PATH
        '';
      };
    });

    # use them via `nix run .#xxx`
    apps = eachSystem ({system, pkgs, ...}: rec {
      default = main;

      main = {
        # TODO: change this script to your own app entry
        type = "app";
        program = "${pkgs.writeShellScript "funix-app" ''
          source ${self.devShells.${system}.default.shellHook}
          funix ./src
        ''}";
      };
    });

  };
}
