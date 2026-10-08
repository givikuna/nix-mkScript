{
  description = "A utility to create script wrappers in nix flakes";

  outputs = { self }: {
    lib = {
      mkScript =
        pkgs:
        {
          customInterpreters ? { },
        }:
        command-name: file-path:
        let
          ext =
            let
              match = builtins.match ".*\\.([^.]+)$" file-path;
            in
            if match != null then
              builtins.head match
            else
              throw "mkScript: couldn't determine extension for ${file-path}";

          defaultInterpreters = {
            "sh" = "${pkgs.bash}/bin/bash";
            "elv" = "${pkgs.elvish}/bin/elvish";
            "py" = "${pkgs.python3}/bin/python3";
            "js" = "${pkgs.nodejs}/bin/node";
            "ts" = "${pkgs.deno}/bin/deno run";
            "nu" = "${pkgs.nushell}/bin/nu";
            "rb" = "${pkgs.ruby}/bin/ruby";
            "pl" = "${pkgs.perl}/bin/perl";
            "lua" = "${pkgs.lua}/bin/lua";
            "php" = "${pkgs.php}/bin/php";
            "awk" = "${pkgs.gawk}/bin/awk -f";
          };

          interpreters = defaultInterpreters // customInterpreters;

          interpreter = interpreters.${ext} or (throw "mkScript: unsupported extension .${ext}");
        in
        pkgs.writeShellScriptBin command-name ''
          ROOT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
          exec ${interpreter} "$ROOT_DIR/${file-path}" "$@"
        '';
    };
  };
}
