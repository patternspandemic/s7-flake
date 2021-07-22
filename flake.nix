{
  description = "s7 Scheme";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-21.05";
    flake-utils.url = "github:numtide/flake-utils";
    s7-src = {
      url = "git+https://cm-gitlab.stanford.edu/bil/s7.git";
      #url = "git+https://cm-gitlab.stanford.edu/bil/s7.git?ref=master&rev=b0cc510b4d1a5be26a44188f94a05f1fd8f6293f";
      flake = false; 
    };
    s7-man = {
      url = "github:mobileink/s7";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, s7-src, s7-man }:
    {
      overlay = import ./overlay.nix { inherit s7-src s7-man; };
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
            #inputsFrom = builtins.attrValues self.packages.${system};
          };

        }
      )
    );
}
