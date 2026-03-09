{
  lib,
  fetchurl,
  runCommand,
}:

let
  depsJson = builtins.fromJSON (builtins.readFile ./deps.json);

  fetchDep =
    dep:
    fetchurl {
      url = dep.url;
      sha256 = dep.sha256;
    };

  fetchedDeps = lib.imap0 (i: dep: {
    inherit (dep)
      group
      artifact
      version
      filename
      ;
    path = builtins.elemAt (lib.map fetchDep depsJson) i;
  }) depsJson;

in
runCommand "gradle-maven-repo" { } ''
  mkdir -p $out

  ${lib.concatStringsSep "\n" (
    map (dep: ''
      groupPath=$(echo "${dep.group}" | tr '.' '/')
      targetDir="$out/$groupPath/${dep.artifact}/${dep.version}"
      mkdir -p "$targetDir"
      cp "${dep.path}" "$targetDir/${dep.filename}"
    '') fetchedDeps
  )}
''
