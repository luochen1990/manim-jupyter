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
      python = pkgs.python3.withPackages (p: with p; [pyaudio]);
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
          pkgs.libgcc.lib
          pkgs.ffmpeg
          pkgs.portaudio
          pkgs.pkg-config
          pkgs.cairo
          pkgs.pango
        ];

        shellHook = ''
          export PATH=$(poetry env info --path)/bin:$PATH
          export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath [
            pkgs.pythonManylinuxPackages.manylinux2014Package
            pkgs.libgcc.lib
            pkgs.openssl
          ]}:$LD_LIBRARY_PATH
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
