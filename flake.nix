{
  description = "Utility flake for creation scripts as wrapped packaged in nix flakes";

  outputs = { self }: {
    lib = {
      mkScript =
        pkgs: command-name: file-path:
        let
          interpreter =
            let
              ext =
                let
                  match = builtins.match ".*\\.([^.]+)$" file-path;
                in
                if match != null then builtins.head match else throw "couldn't determine script extension";
            in
            {
              "sh" = "${pkgs.bash}/bin/bash";
              "elv" = "${pkgs.elvish}/bin/elvish";
              "py" = "${pkgs.python3}/bin/python3";
              "js" = "${pkgs.nodejs}/bin/node";
              "nu" = "${pkgs.nushell}/bin/nu";
            }
            .${ext} or (throw "unsupported .${ext}");
        in
        pkgs.writeShellScriptBin command-name ''
          ROOT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
          exec ${interpreter} "$ROOT_DIR/${file-path}" "$@"
        '';
    };
  };
}
