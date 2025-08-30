{ stdenv
, lib
, cmake
, fetchFromGitHub
}:

stdenv.mkDerivation rec {
  pname = "cimgui";
  version = "1.89.9"; # match a known cimgui tag when updating

  src = fetchFromGitHub {
    owner = "cimgui";
    repo = "cimgui";
    rev = version;
    # Hash pinned from fetch output (update when bumping revision)
    hash = "sha256-Y904rzgJnehRF9iJTtlsMZUe9s+oBXN7Nq1IRRuj0Pw=";
    fetchSubmodules = true; # ensures bundled imgui submodule is available
  };

  nativeBuildInputs = [ cmake ];

  # Let cmake do the default configure/build/install.
  # cimgui's CMakeLists installs headers and library.
  cmakeFlags = [
    # Enable shared library if supported by upstream cmake (fallbacks harmlessly otherwise)
    "-DBUILD_SHARED_LIBS=ON"
  ];

  # Build in parallel where possible
  enableParallelBuilding = true;

  # Upstream installs the shared lib into $out root and no headers.
  # Move the library into $out/lib and install headers for consumers.
  postInstall = ''
    mkdir -p "$out/lib"
    # Relocate installed library if placed in $out/
    if [ -f "$out/cimgui.so" ]; then mv "$out/cimgui.so" "$out/lib/"; fi
    if [ -f "$out/cimgui.dylib" ]; then mv "$out/cimgui.dylib" "$out/lib/"; fi

    # Headers: cimgui.h and imgui headers (including backends)
    mkdir -p "$out/include"
    if [ -f "$src/cimgui.h" ]; then install -Dm644 "$src/cimgui.h" "$out/include/cimgui.h"; fi

    if [ -d "$src/imgui" ]; then
      mkdir -p "$out/include/imgui"
      cp -v "$src"/imgui/*.h "$out/include/imgui/"
      if [ -d "$src/imgui/backends" ]; then
        mkdir -p "$out/include/imgui/backends"
        cp -v "$src"/imgui/backends/*.h "$out/include/imgui/backends/" || true
      fi
    fi

    # pkg-config file for consumers
    mkdir -p "$out/lib/pkgconfig"
    cat > "$out/lib/pkgconfig/cimgui.pc" <<EOF
prefix=$out
exec_prefix=\''${prefix}
libdir=\''${prefix}/lib
includedir=\''${prefix}/include

Name: cimgui
Description: Thin C-API wrapper for Dear ImGui
Version: ${version}
Libs: -L\''${libdir} -lcimgui
Cflags: -I\''${includedir}
EOF
  '';

  meta = with lib; {
    description = "Thin c-api wrapper for Dear ImGui";
    homepage = "https://github.com/cimgui/cimgui";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
