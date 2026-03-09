{
  description = "Application to track and log goals";

  nixConfig = {
    extra-substituters = [ "https://amadejkastelic.cachix.org" ];
    extra-trusted-public-keys = [
      "amadejkastelic.cachix.org-1:EiQfTbiT0UKsynF4q3nbNYjNH6/l7zuhrNkQTuXmyOs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      pre-commit-hooks,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            android_sdk.accept_license = true;
            allowUnfree = true;
          };
        };

        buildToolsVersion = "35.0.0";
        androidComposition = pkgs.androidenv.composeAndroidPackages {
          buildToolsVersions = [
            buildToolsVersion
            "34.0.0"
            "28.0.3"
          ];
          platformVersions = [
            "36"
            "35"
            "34"
            "28"
          ];
          abiVersions = [
            "armeabi-v7a"
            "arm64-v8a"
          ];
          includeNDK = true;
          cmakeVersions = [ "3.22.1" ];
        };
        androidSdk = androidComposition.androidsdk;

        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixfmt-rfc-style.enable = true;
            dart-analyze.enable = true;
            dart-format.enable = true;
          };
        };
      in
      {
        devShells.default = pkgs.callPackage ./nix/shell.nix {
          inherit
            pkgs
            androidSdk
            buildToolsVersion
            pre-commit-check
            ;
        };
      }
    );
}
