{
  description = "s7 Scheme";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-21.05";
    flake-utils.url = "github:numtide/flake-utils";
    s7-src = {
      url = "git+https://cm-gitlab.stanford.edu/bil/s7.git";
      # url = "git+https://cm-gitlab.stanford.edu/bil/s7.git?ref=master&rev=97d888394d46f2e22cbfa1df37fbd4587eab3ab7";
      flake = false; 
    };
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

          devShell = pkgs.mkShell {
            buildInputs = with pkgs; [ s7 ];
            inputsFrom = builtins.attrValues self.packages.${system};
          };

        }
      )
    );
}