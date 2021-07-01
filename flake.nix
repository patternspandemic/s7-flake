{
  description = "s7 Scheme";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-21.05";
    flake-utils.url = "github:numtide/flake-utils";
    s7-src = { url = "git+https://cm-gitlab.stanford.edu/bil/s7.git"; flake = false; };
  };

  outputs = { self, nixpkgs, flake-utils, s7-src }:
    {
      overlay = import ./overlay.nix { inherit s7-src; };
    }
    //
    ( # TODO: Support other s7's other systems (freebsd, openbsd, osx, windows).
      flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            # config = {
            #   #allowBroken = true;
            #   #allowUnfree = true;
            # };
            overlays = [
              self.overlay
            ];
          };
        in rec
        {

          packages = flake-utils.lib.flattenTree { s7 = pkgs.s7; };

          # apps.x86_64-linux = {
          #   kinc-shader = { type = "app"; program = "${self.packages.x86_64-linux.kinc-shader}/bin/kinc-shader"; };
          #   kinc-texture = { type = "app"; program = "${self.packages.x86_64-linux.kinc-texture}/bin/kinc-texture"; };
          # };
#          apps.kinc-shader = flake-utils.lib.mkApp { drv = packages.kinc-shader; };
#          apps.kinc-texture = flake-utils.lib.mkApp { drv = packages.kinc-texture; };
          apps.nrepl = flake-utils.lib.mkApp { drv = packages.nrepl; };

#          devShell = import ./devshell.nix { inherit pkgs; };
          # devShell = pkgs.mkShell {
          #   buildInputs = with haskellPackages; [
          #     haskell-language-server
          #     ghcid
          #     cabal-install
          #   ];
          #   inputsFrom = builtins.attrValues self.packages.${system};
          # };


          checks = { };
        }
      )
    );
}
