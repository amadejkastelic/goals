import json
import sys
from pathlib import Path
from urllib.parse import unquote, urlparse

import yaml


def get_package(pubspec_path: Path, dev_dependencies: bool = False):
    with pubspec_path.open("r", encoding="utf-8") as f:
        pubspec = yaml.load(f, Loader=yaml.CSafeLoader)
    package = {
        "name": pubspec["name"],
        "version": pubspec.get("version") or "0.0.0",
        "dependencies": list(pubspec.get("dependencies") or {}),
    }
    if dev_dependencies:
        package["devDependencies"] = list(pubspec.get("dev_dependencies") or {})
    return package


def main():
    package_config_path = Path(sys.argv[1])
    pubspec_path = Path(sys.argv[2])

    with package_config_path.open("r", encoding="utf-8") as f:
        package_config = json.load(f)

    package_graph = []
    root_package = get_package(pubspec_path, dev_dependencies=True)

    for data in package_config.get("packages", []):
        if data["name"] == root_package["name"] or data["rootUri"] == "flutter_gen":
            continue
        try:
            pkg_path = Path(unquote(urlparse(data["rootUri"]).path))
            package_graph.append(get_package(pkg_path / "pubspec.yaml"))
        except Exception:
            pass

    package_graph.append(root_package)
    print(
        json.dumps(
            {
                "roots": [root_package["name"]],
                "packages": package_graph,
                "configVersion": 1,
            },
            indent=2,
            ensure_ascii=False,
        )
    )


if __name__ == "__main__":
    main()
