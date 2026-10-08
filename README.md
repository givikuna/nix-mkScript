# mkScript Flake

A Nix flake utility that creates runnable shell commands from your project scripts, automatically detecting the correct interpreter based on the file extension.

It will create a nix package with `writeShellScriptBin`.

It ensures your scripts always execute relative to the **root of your Git repository**, so you can run them from any subdirectory without breaking relative paths.

## Supported Languages

Out of the box: `.sh`, `.py`, `.js`, `.ts` (via deno), `.nu`, `.elv`, `.rb`, `.pl`, `.lua`, `.php`, `.awk`.

## Basic Usage

In your project's `flake.nix`:

```nix
{
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        mk-script.url = "github:givikuna/nix-mkScript";
    };

    outputs = { self, nixpkgs, mk-script }:
    let
        system = "x86_64-linux";
        pkgs = nixpkgs.legacyPackages.${system};

        mkScript = mk-script.lib.mkScript pkgs {};
    in {
        devShells.${system}.default = pkgs.mkShell {
            buildInputs = [
                (mkScript "format" "scripts/format.py")
                (mkScript "clean" "scripts/clean.sh")
            ];
        };
    };
}
```

## Overriding Interpreters

You can override default interpreters or add new ones by passing `customInterpreters`:

```Nix
let
    mkScript = mk-script.lib.mkScript pkgs {
        customInterpreters = {
            # overriding
            "py" = "${pkgs.python311}/bin/python3.11";

            # adding a new language
            "go" = "${pkgs.go}/bin/go run";
        };
    };
in {
    ...
}
```

## Usage with `flake-parts`

An example of using `nix-mkScript` with `flake-parts`:

```nix
{
    description = "Some project using flake-parts";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        flake-parts.url = "github:hercules-ci/flake-parts";

        mk-script.url = "github:givikuna/nix-mkScript";
    };

    outputs = inputs@{ flake-parts, nixpkgs, mk-script, ... }:
        flake-parts.lib.mkFlake { inherit inputs; } {
            systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];

            perSystem = { pkgs, system, ... }:
                let
                    mkScript = mk-script.lib.mkScript pkgs {};
                in
                {
                    devShells.default = pkgs.mkShell {
                        packages = [
                            (mkScript "build-docs" "scripts/build.py")
                            (mkScript "lint" "scripts/lint.nu")
                        ];
                    };
                };
    };
}
```
