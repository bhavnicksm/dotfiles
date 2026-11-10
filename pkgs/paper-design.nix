{
  appimageTools,
  asar,
  fetchurl,
  lib,
  python3,
}:

let
  pname = "paper-design";
  version = "0.5.18";

  # Pin the version/path published in ToDesktop's latest-linux.yml. The
  # build id is not derivable from the version, so change version, URL,
  # and hash together when updating.
  src = fetchurl {
    url = "https://download.todesktop.com/2601167vjw8xe/paper-desktop-0.5.18-build-261031pthw9s82w-x86_64.AppImage";
    hash = "sha256-TxJ8+a8bb2XOGv7YzDoPcQ5RZ794nzbAFvRCr5aECrk=";
  };

  appimageContents = appimageTools.extract {
    inherit pname version src;

    # ToDesktop's runtime and the bundled electron-updater both expose an
    # isUpdateAvailable method. Returning early prevents accepting,
    # downloading, or installing a newer version; update feed checks still
    # occur. This does not touch productName/desktopName/user-data paths.
    postExtract = ''
      work="$(mktemp -d)"
      trap 'rm -rf "$work"' EXIT
      app="$work/app"

      ${lib.getExe asar} extract "$out/resources/app.asar" "$app"

      ${lib.getExe python3} - "$app" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])


def disable_update_check(path, signature, early_return):
    text = path.read_text(encoding="utf-8")
    count = text.count(signature)
    if count != 1:
        raise SystemExit(
            f"expected exactly one occurrence of {signature!r} in {path}, "
            f"found {count}"
        )
    path.write_text(
        text.replace(signature, signature + early_return, 1),
        encoding="utf-8",
    )


# The minified main-process bundle contains a copy of electron-updater.
disable_update_check(
    root / "dist/main.cjs",
    "async isUpdateAvailable(t){",
    "return!1;",
)

# The unpacked electron-updater copy used by ToDesktop's runtime.
disable_update_check(
    root / "node_modules/electron-updater/out/AppUpdater.js",
    "async isUpdateAvailable(updateInfo) {",
    "\n        return false;",
)
PY

      # Files in the original app.asar.unpacked are executable in the
      # AppImage. asar extraction loses that mode for unpacked entries, so
      # restore it before repacking.
      chmod 755 \
        "$app/dist/cli-bin/linux-x64/paper" \
        "$app/node_modules/@typescript/typescript-linux-x64/lib/tsc"

      # Keep the same six unpacked entries as the original archive. The
      # brace glob is one --unpack-dir expression; repeating the option
      # would only retain the last value.
      ${lib.getExe asar} pack "$app" "$out/resources/app.asar" \
        --unpack-dir '{dist/cli-bin,node_modules/@typescript}'
    '';
  };
in
(appimageTools.wrapAppImage {
  inherit pname version;
  src = appimageContents;

  extraInstallCommands = ''
    # Keep the stable desktop ID: existing MIME handlers point at
    # paper-desktop.desktop, so do not rename it to paper-design.desktop.
    install -Dm644 ${appimageContents}/paper-desktop.desktop \
      $out/share/applications/paper-desktop.desktop
    install -Dm644 \
      ${appimageContents}/usr/share/icons/hicolor/1024x1024/apps/paper-desktop.png \
      $out/share/icons/hicolor/1024x1024/apps/paper-desktop.png

    # The shipped launcher hardcodes --no-sandbox; use the wrapped package
    # executable and let the session/wrapper decide sandbox flags.
    substituteInPlace $out/share/applications/paper-desktop.desktop \
      --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=paper-design %U'
  '';

  meta = {
    description = "Native desktop client for Paper, a browser-based collaborative design tool";
    homepage = "https://paper.design";
    changelog = "https://paper.design/build-log";
    license = lib.licenses.unfree;
    mainProgram = "paper-design";
    platforms = [ "x86_64-linux" ];
  };
})
