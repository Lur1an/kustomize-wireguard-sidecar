{
  description =  "DevShell";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { nixpkgs, flake-utils, ...}:
    flake-utils.lib.eachDefaultSystem (system:
      let
        lib = nixpkgs.lib;
        pkgs = nixpkgs.legacyPackages.${system};
        poetry2nix = inputs.poetry2nix.lib.mkPoetry2Nix { inherit pkgs; };
        pythonEnv = poetry2nix.mkPoetryEnv {
          preferWheels = true;
          python = pkgs.python311;
          projectDir = ./.;
          overrides = poetry2nix.overrides.withDefaults (final: prev: {
            selenium = prev.selenium.overridePythonAttrs (old: {
              buildInputs = (old.buildInputs or [ ]) ++ [ prev.setuptools ];
            });
          });
        };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [ pythonEnv ];
          packages = [ pkgs.poetry ];
          PYTHONPATH = "${pythonEnv.sitePackages}";
        };
      });
}
