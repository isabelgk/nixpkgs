{ lib, stdenv, fetchFromGitHub
, meson, ninja, pkg-config, makeWrapper
, gdk-pixbuf, libwebp
}:
let
  moduleDir = gdk-pixbuf.moduleDir;

  # turning lib/gdk-pixbuf-#.#/#.#.#/loaders into lib/gdk-pixbuf-#.#/#.#.#/loaders.cache
  # removeSuffix is just in case moduleDir gets a trailing slash
  loadersPath = (lib.strings.removeSuffix "/" gdk-pixbuf.moduleDir) + ".cache";
in
stdenv.mkDerivation rec {
  pname = "webp-pixbuf-loader";
  version = "0.0.6";

  src = fetchFromGitHub {
    owner = "aruiz";
    repo = pname;
    rev = version;
    sha256 = "sha256-dcdydWYrXZJjo4FxJtvzGzrQLOs87/BmxshFZwsT2ws=";
  };

  # It looks for gdk-pixbuf-thumbnailer in this package's bin rather than the gdk-pixbuf bin. We need to patch that.
  postPatch = ''
    substituteInPlace webp-pixbuf.thumbnailer.in --replace @bindir@/gdk-pixbuf-thumbnailer $out/bin/webp-thumbnailer
  '';

  nativeBuildInputs = [ gdk-pixbuf meson ninja pkg-config makeWrapper ];
  buildInputs = [ gdk-pixbuf libwebp ];

  mesonFlags = [
    "-Dgdk_pixbuf_query_loaders_path=${gdk-pixbuf.dev}/bin/gdk-pixbuf-query-loaders"
    "-Dgdk_pixbuf_moduledir=${placeholder "out"}/${moduleDir}"
  ];

  # It assumes gdk-pixbuf-thumbnailer can find the webp loader in the loaders.cache referenced by environment variable, breaking containment.
  # So we replace it with a wrapped executable.
  postInstall = ''
    mkdir -p $out/bin
    makeWrapper ${gdk-pixbuf}/bin/gdk-pixbuf-thumbnailer $out/bin/webp-thumbnailer \
      --set GDK_PIXBUF_MODULE_FILE $out/${loadersPath}
  '';

  # environment variables controlling loaders.cache generation by gdk-pixbuf-query-loaders
  preInstall = ''
    export GDK_PIXBUF_MODULE_FILE=$out/${loadersPath}
    export GDK_PIXBUF_MODULEDIR=$out/${moduleDir}
  '';

  meta = with lib; {
    description = "WebP GDK Pixbuf Loader library";
    homepage = "https://github.com/aruiz/webp-pixbuf-loader";
    license = licenses.lgpl2Plus;
    platforms = platforms.unix;
    maintainers = [ maintainers.cwyc ];
    # meson.build:16:0: ERROR: Program or command 'gcc' not found or not executable
    broken = stdenv.isDarwin;
  };
}
