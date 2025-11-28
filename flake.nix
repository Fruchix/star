{
  description = "A Unix command line bookmark manager.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.11";
    flakeutils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flakeutils }:
    flakeutils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system}; in
      {
        packages = rec {
          default = pkgs.stdenv.mkDerivation {
            name = "star";
            src = ./.;
            buildInputs = with pkgs; [
              coreutils
              findutils
              unixtools.column
              bash
            ];
            installPhase = ''
            ./configure --prefix="$out"
            bash ./install.sh
            '';
          };
        };
      }
    );
}



