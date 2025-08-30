# cimgui-flake

Nix flake that packages [cimgui](https://github.com/cimgui/cimgui) (a thin C-API wrapper for Dear ImGui) from source.

- Builds the shared library via CMake
- Fetches the `imgui` submodule
- Installs headers: `cimgui.h` and `imgui/*.h` (including `imgui/backends/*.h`)
- Provides a `pkg-config` file: `lib/pkgconfig/cimgui.pc`

## Outputs

- `packages.<system>.cimgui` (also `default`)
- `devShells.<system>.default`
- `overlays.default` exporting `cimgui`

## Build

```sh
nix build .#cimgui
# Library: result/lib/cimgui.so
# Headers: result/include (cimgui.h and imgui/*)
```

Dev shell with basic tooling:
```sh
nix develop
```

## Zig Usage (pkg-config)

Using `pkg-config` flags for include/lib paths and linking:

```sh
# Get store path of the build
CIMGUI=$(nix build .#cimgui --no-link --print-out-paths)

# Make sure pkg-config can find the .pc
export PKG_CONFIG_PATH="$CIMGUI/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

# Example (C/zig cc style):
zig cc $(pkg-config --cflags --libs cimgui) your_app.c -o your_app
```

If you prefer manual flags:
- Includes: `-I$CIMGUI/include`
- Link: `-L$CIMGUI/lib -lcimgui -lstdc++` (on macOS use `-lc++`)

Notes:
- Do NOT also link `imgui` separately. This build already compiles and bundles Dear ImGui into the cimgui shared library; adding `-limgui` can cause duplicate/undefined symbols.
- The package provides both `cimgui.so` and a symlink `libcimgui.so`, so `-lcimgui` resolves correctly.

## Use As Overlay

In another flake, add this repo and overlay:

```nix
{
  inputs.cimgui-flake.url = "github:YOUR_USER/cimgui-flake"; # or a local path

  outputs = { self, nixpkgs, cimgui-flake, ... }:
    let
      system = "x86_64-linux"; # or your system
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ cimgui-flake.overlays.default ];
      };
    in {
      packages.${system}.my-app = pkgs.stdenv.mkDerivation {
        # now pkgs.cimgui is available
        buildInputs = [ pkgs.cimgui ];
      };
    };
}
```

## Pin / Update Version

Version is pinned in `pkgs/cimgui/default.nix`:

- Change `version = "<tag>";` to a valid upstream tag (e.g. `1.90.1`).
- Keep `rev = version;`.
- Run `nix build .#cimgui` once to get a hash mismatch; copy the printed `sha256` into the `hash` field and rebuild.

You can list available tags:
```sh
git ls-remote --tags https://github.com/cimgui/cimgui.git
```

## Notes / Scope

- Only the core cimgui library is built and installed. Rendering/platform backends are header-only; you link the backend(s) you use in your app.
- On macOS, the library will be `cimgui.dylib`; on Linux, `cimgui.so`.
- Dev shell includes: `cmake`, `ninja`, `pkg-config`, `gcc`, `git`.

## Verifying Symbols / Linking

To check that C API symbols are exported (e.g. `igCreateContext`):

```sh
nm -D $(nix build .#cimgui --no-link --print-out-paths)/lib/libcimgui.so | grep igCreateContext
```

If symbols are present but your project fails to link, ensure you are:
- pulling flags from `pkg-config cimgui`,
- not linking `imgui` separately,
- adding your platform/backend link flags (e.g. `$(pkg-config --cflags --libs sdl2)` and `-lGL` or `$(pkg-config --cflags --libs glfw3)` and `-lGL`).

## License

cimgui is MIT-licensed by its authors. This flake only provides build definitions.
