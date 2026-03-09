{
  pkgs,
  androidSdk,
  buildToolsVersion,
  pre-commit-check ? null,
}:
pkgs.mkShell {
  ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
  ANDROID_NDK_ROOT = "${androidSdk}/libexec/android-sdk/ndk-bundle";
  GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/libexec/android-sdk/build-tools/${buildToolsVersion}/aapt2";

  LD_LIBRARY_PATH =
    with pkgs;
    lib.makeLibraryPath [
      stdenv.cc.cc.lib
      zlib
      sqlite.out
    ];

  buildInputs = with pkgs; [
    androidSdk
    dart
    flutter
    jdk17
    sqlite
  ];

  shellHook = if pre-commit-check != null then pre-commit-check.shellHook else "";
}
