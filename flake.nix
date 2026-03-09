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

        flutterDeps =
          (import ./nix/deps {
            inherit (pkgs)
              runCommand
              yq
              jq
              pub2nix
              dart
              flutter
              python3
              ;
          })
            {
              pubspecLockFile = ./pubspec.lock;
              src = ./.;
            };

        pre-commit = import ./nix/pre-commit.nix {
          inherit pkgs;
          inherit pre-commit-hooks system flutterDeps;
          src = ./.;
        };

        goalsPackage =
          if pkgs.lib.hasPrefix "x86_64-linux" system || pkgs.lib.hasPrefix "aarch64-linux" system then
            pkgs.callPackage ./nix/packages {
              flutter = pkgs.flutter;
              inherit (pkgs)
                makeDesktopItem
                copyDesktopItems
                pkg-config
                gtk3
                glib
                pcre
                sqlite
                ;
            }
          else
            null;
      in
      {
        devShells.default = pkgs.callPackage ./nix/shell.nix {
          inherit
            pkgs
            androidSdk
            buildToolsVersion
            ;
          pre-commit-check = pre-commit.check;
        };

        packages = pkgs.lib.optionalAttrs (goalsPackage != null) {
          default = goalsPackage;
          goals = goalsPackage;
        };

        apps = pkgs.lib.optionalAttrs (goalsPackage != null) {
          default = {
            type = "app";
            program = "${goalsPackage}/bin/goals";
          };
        };

        checks = {
          pre-commit-check = pre-commit.check;
        };
      }
    );
}
