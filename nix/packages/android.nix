{
  lib,
  stdenv,
  flutter,
  jdk17,
  androidSdk,
  cmake,
  ninja,
  gradleDeps,
  version,
}:

stdenv.mkDerivation {
  pname = "goals-android";
  inherit version;

  src = ../..;

  nativeBuildInputs = [
    flutter
    jdk17
    cmake
    ninja
  ];

  ANDROID_HOME = "${androidSdk}/share/android-sdk";
  ANDROID_SDK_ROOT = "${androidSdk}/share/android-sdk";
  ANDROID_NDK_HOME = "${androidSdk}/share/android-sdk/ndk-bundle";
  JAVA_HOME = jdk17;
  HOME = "/build";

  configurePhase = ''
    runHook preConfigure

    mkdir -p android
    cat >> android/gradle.properties <<EOF
    android.cmake.path=${cmake}/bin
    android.ninja.path=${ninja}/bin
    android.cmake.makeProgram=${ninja}/bin/ninja
    org.gradle.daemon=false
    org.gradle.parallel=true
    EOF

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    export HOME=$(mktemp -d)
    export GRADLE_USER_HOME=$HOME/gradle
    mkdir -p $GRADLE_USER_HOME/caches/modules-2/files-2.1

    if [ "$(ls -A ${gradleDeps} 2>/dev/null)" ]; then
      cp -r ${gradleDeps}/* $GRADLE_USER_HOME/caches/modules-2/files-2.1/
    fi

    flutter build apk --release --offline

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp build/app/outputs/flutter-apk/app-release.apk $out/goals-${version}.apk

    runHook postInstall
  '';

  meta = {
    description = "Goals Android APK";
    homepage = "https://github.com/amadejkastelic/goals";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
