{
  runCommand,
  yq,
  jq,
  pub2nix,
  dart,
  flutter,
  python3,
}:

{
  pubspecLockFile,
  src ? null,
  gitHashes ? { },
}:

let
  pubspecLock = builtins.fromJSON (
    builtins.readFile (
      runCommand "pubspec-lock-json" {
        nativeBuildInputs = [ yq ];
      } "yq '.' '${pubspecLockFile}' > $out"
    )
  );

  flutterUnwrapped = flutter.unwrapped or flutter;

  pubspecLockData = pub2nix.readPubspecLock {
    inherit src gitHashes;
    packageRoot = ".";
    inherit pubspecLock;
    sdkSourceBuilders = {
      dart =
        name:
        runCommand "dart-sdk-${name}" { passthru.packageRoot = "."; } ''
          if [ -d "${dart}/pkg/${name}" ]; then
            ln -s "${dart}/pkg/${name}" "$out"
          else
            echo 1>&2 'Dart SDK package not found: ${name}'
            exit 1
          fi
        '';
      flutter =
        name:
        runCommand "flutter-sdk-${name}" { passthru.packageRoot = "."; } ''
          for path in \
            "${flutterUnwrapped}/packages/${name}" \
            "${flutter.cacheDir}/bin/cache/pkg/${name}"
          do
            if [ -d "$path" ]; then
              ln -s "$path" "$out"
              break
            fi
          done
          if [ ! -e "$out" ]; then
            echo 1>&2 'Flutter SDK package not found: ${name}'
            exit 1
          fi
        '';
    };
  };

  packageConfig = pub2nix.generatePackageConfig {
    dependencies = builtins.concatLists (builtins.attrValues pubspecLockData.dependencies);
    inherit (pubspecLockData) dependencySources;
  };
in
runCommand "flutter-deps"
  {
    nativeBuildInputs = [
      python3
      python3.pkgs.pyyaml
      jq
    ];
    passthru = {
      inherit (pubspecLockData) dependencySources;
      inherit packageConfig;
    };
  }
  ''
    mkdir -p $out/.dart_tool
    cp ${packageConfig} $out/.dart_tool/package_config.json
    python3 ${./package-graph.py} $out/.dart_tool/package_config.json ${src}/pubspec.yaml > $out/.dart_tool/package_graph.json
  ''
