{
  description = "cimgui packaged as a Nix flake (builds from source)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

  outputs = { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forEachSystem = f: nixpkgs.lib.genAttrs systems (system:
        f (import nixpkgs { inherit system; }));
    in {
      packages = forEachSystem (pkgs: {
        default = pkgs.callPackage ./pkgs/cimgui { };
        cimgui = pkgs.callPackage ./pkgs/cimgui { };
      });

      overlays.default = final: prev: {
        cimgui = final.callPackage ./pkgs/cimgui { };
      };

      devShells = forEachSystem (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            cmake
            ninja
            pkg-config
            gcc
            git
          ];
        };
      });
    };
}
