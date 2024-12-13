{
  description = "Greeneye utilities flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs }: 
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages.${system} = {
        scripts = pkgs.stdenv.mkDerivation {
          name = "my-scripts";
          src = ./scripts;
          buildInputs = [ pkgs.bash ];
          installPhase = ''
          mkdir -p $out/bin
          cp *.sh $out/bin/
          chmod +x $out/bin/*
          '';
        };
      };

      homeManagerModules.default = { pkgs, ... }: {
        home.sessionVariables = {
          FLUXCD_REPO_NAME = "rt-versions";
          VAULT_ADDR = "https://sod.tail6954.ts.net/";
        };
        
        home.packages = with pkgs; [
          fd
          ripgrep
          tailscale
          azure-cli
          kubectl
          gawk
          fzf
          coreutils
          vault
        ];

      };

      defaultPackage.${system} = self.packages.${system}.scripts;
    };
}
