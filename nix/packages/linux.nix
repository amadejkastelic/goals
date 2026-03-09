{
  lib,
  flutter,
  makeDesktopItem,
  copyDesktopItems,
  pkg-config,
  gtk3,
  glib,
  pcre,
  sqlite,
  version,
}:

flutter.buildFlutterApplication {
  pname = "goals";
  inherit version;

  src = ../..;

  pubspecLock = lib.importJSON ./pubspec.lock.json;

  nativeBuildInputs = [
    copyDesktopItems
    pkg-config
  ];

  buildInputs = [
    gtk3
    glib
    pcre
    sqlite
  ];

  flutterBuildFlags = [ ];

  env.DART_VM_OPTIONS = "--no-native-assets";

  desktopItems = [
    (makeDesktopItem {
      name = "goals";
      exec = "goals";
      icon = "goals";
      genericName = "Goal Tracker";
      desktopName = "Goals";
      comment = "Track personal goals with daily journal entries";
      categories = [
        "Office"
        "Qt"
        "Utility"
      ];
      keywords = [
        "goals"
        "tracker"
        "journal"
        "productivity"
      ];
      startupNotify = true;
    })
  ];

  postInstall = ''
    mkdir -p $out/share/icons/hicolor/128x128/apps
    if [ -f "$src/assets/icon/app_icon.png" ]; then
      cp $src/assets/icon/app_icon.png $out/share/icons/hicolor/128x128/apps/goals.png
    fi
  '';

  meta = {
    description = "Track personal goals with daily journal entries";
    homepage = "https://github.com/amadejkastelic/goals";
    license = lib.licenses.gpl3Only;
    mainProgram = "goals";
    platforms = lib.platforms.linux;
  };
}
