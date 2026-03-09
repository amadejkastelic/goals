{
  pkgs,
  pre-commit-hooks,
  system,
  src,
  flutterDeps,
}:

let
  flutterAnalyze = pkgs.writeShellScriptBin "flutter-analyze" ''
    set -e
    if [ ! -f .dart_tool/package_config.json ]; then
      rm -rf .dart_tool
      cp -r ${flutterDeps}/.dart_tool .dart_tool
      chmod -R u+w .dart_tool
    fi
    exec ${pkgs.flutter}/bin/flutter --disable-analytics analyze "$@"
  '';
in
{
  inherit flutterAnalyze;

  check = pre-commit-hooks.lib.${system}.run {
    inherit src;
    hooks = {
      nixfmt.enable = true;

      dart-format.enable = true;

      flutter-analyze = {
        enable = true;
        name = "flutter analyze";
        entry = "${flutterAnalyze}/bin/flutter-analyze";
        files = "\\.dart$";
        language = "system";
        pass_filenames = false;
      };
    };
  };
}
