{
  description = "A utility to create script wrappers in nix flakes";

  outputs = { self }: {
    lib = {
      mkScript =
        pkgs:
        {
          customInterpreters ? { },
          env ? { },
          src ? null,
        }:
        command-name: file-path:
        let
          extMatch = builtins.match ".*\\.([^.]+)$" file-path;
          ext = if extMatch != null then builtins.head extMatch else null;

          defaultInterpreters = {
            "sh" = "${pkgs.bash}/bin/bash";
            "elv" = "${pkgs.elvish}/bin/elvish";
            "py" = "${pkgs.python3}/bin/python3";
            "js" = "${pkgs.nodejs}/bin/node";
            "ts" = "${pkgs.deno}/bin/deno run";
            "nu" = "${pkgs.nushell}/bin/nu";
            "rb" = "${pkgs.ruby}/bin/ruby";
            "pl" = "${pkgs.perl}/bin/perl";
          };

          interpreters = defaultInterpreters // customInterpreters;

          interpreter =
            if ext != null && interpreters ? ${ext} then
              interpreters.${ext}
            else if ext == null && src != null then
              let
                targetPath = src + "/${file-path}";
                content = builtins.readFile targetPath;
                firstLine = builtins.head (pkgs.lib.splitString "\n" content);
                shebangMatch = builtins.match "^#! *(.*)$" firstLine;
                shebang = if shebangMatch != null then builtins.head shebangMatch else "";
              in
              if builtins.match ".*python3?.*" shebang != null then
                "${pkgs.python3}/bin/python3"
              else if builtins.match ".*node.*" shebang != null then
                "${pkgs.nodejs}/bin/node"
              else if builtins.match ".*bash.*" shebang != null then
                "${pkgs.bash}/bin/bash"
              else if builtins.match ".*sh.*" shebang != null then
                "${pkgs.bash}/bin/sh"
              else if builtins.match ".*nu.*" shebang != null then
                "${pkgs.nushell}/bin/nu"
              else
                throw "mkScript: unsupported shebang '${shebang}' in${file-path}. add a customInterpreter or standard extension. be a good bloke."
            else
              throw "mkScript: no extension found for ${file-path}. to enable shebang parsing, pass 'src = ./.;' in the mkScript config.";

          envLines = pkgs.lib.concatStringsSep "\n" (
            pkgs.lib.mapAttrsToList (k: v: "export ${k}=${pkgs.lib.escapeShellArg (toString v)}") env
          );

        in
        pkgs.writeShellApplication {
          name = command-name;
          text = ''
            ${envLines}

            ROOT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
            TARGET="$ROOT_DIR/${file-path}"

            if [ ! -f "$TARGET" ]; then
              echo "error: mkScript cannot find $TARGET" >&2
              exit 1
            fi

            exec ${interpreter} "$TARGET" "$@"
          '';
        };
    };
  };
}
