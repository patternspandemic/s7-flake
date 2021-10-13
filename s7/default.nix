### TODO
#
# - Restore nrepl build when notcurses version updated.
#
# Configure *cload-directory* - the dir for cload output.
#           CLOAD_DIR
#
# Allow configurable INITIAL_HEAP_SIZE and other compile-time defaults.
#
# Other possible perf opts used in timing:
#   -march=native -fomit-frame-pointer -funroll-loops
# Other special files:
#   ffitest.c
#   gdbinit
#   libarb_s7.c
#   s7test.scm
#
###

{ stdenv, lib
, s7-src
, s7-man
# , arb ?
, gdb
, gdbm
, gmp
, gsl
, mpfr
, libmpc
, notcurses
, pkg-config
, utf8proc
, disableDeprecated ? true
, haveComplexNumbers ? true
, haveComplexTrig ? true
, withCLoader ? true
, withExtraExponentMarkers ? false
, withGmp ? true
, withImmutableUnquote ? false
, withMain ? false
, withMultithreadChecks ? false
, withPureS7 ? false
, withSystemExtras ? true
, s7Debugging ? false
}:

let
  nreplLibs = [ notcurses ];
  otherLibs = [ gdb gdbm gsl pkg-config utf8proc ];
  multiPrecisionLibs = [ gmp gmp.dev libmpc mpfr mpfr.dev ];

  gmpLdOpts = "-lgmp -lmpc -lmpfr";

  toDefineVal = b: if !b then "0" else "1";
in
  stdenv.mkDerivation {
    name = "s7"; # or, pname & version (how to extract from s7.h?)
    src = s7-src;

    buildInputs = nreplLibs ++ otherLibs ++ (lib.optionals withGmp multiPrecisionLibs);
    # TODO: propogatedBuildInputes? nativeBuildInputs?

    buildPhase = ''
      # Create the s7 configuration header.
      cat << EOF > ./mus-config.h
#define DISABLE_DEPRECATED ${toDefineVal disableDeprecated}
#define HAVE_COMPLEX_NUMBERS ${toDefineVal haveComplexNumbers}
#define HAVE_COMPLEX_TRIG ${toDefineVal haveComplexTrig}
// #define WITH_C_LOADER ${toDefineVal withCLoader}
#define WITH_EXTRA_EXPONENT_MARKERS ${toDefineVal withExtraExponentMarkers}
#define WITH_GMP ${toDefineVal withGmp}
#define WITH_IMMUTABLE_UNQUOTE ${toDefineVal withImmutableUnquote}
// #define WITH_MAIN ${toDefineVal withMain}
#define WITH_MULTITHREAD_CHECKS ${toDefineVal withMultithreadChecks}
// #define WITH_PURE_S7 ${toDefineVal withPureS7}
// #define WITH_SYSTEM_EXTRAS ${toDefineVal withSystemExtras}
#define S7_DEBUGGING ${toDefineVal s7Debugging}
#define S7_LOAD_PATH "${builtins.placeholder "out"}/s7"
EOF

      # Build the dumb repl.
      gcc s7.c -o s7d -DWITH_MAIN -DWITH_C_LOADER=0 -I. -O2 -g -ldl -lm ${lib.optionalString withGmp gmpLdOpts} -Wl,-export-dynamic
      
      # Build the repl with the c loader.
      gcc s7.c -o s7i -DWITH_MAIN -I. -O2 -g -ldl -lm ${lib.optionalString withGmp gmpLdOpts} -Wl,-export-dynamic
      
      # Build the notcurses repl.
      # FIXME: nrepl is missing proper load-path
      #gcc -o s7n s7.c -DWITH_MAIN -DWITH_NOTCURSES -O2 -I. -lm -ldl -lnotcurses-core ${lib.optionalString withGmp gmpLdOpts} -Wl,-export-dynamic
#      gcc -c s7.c -O2 -I. -lm -ldl ${lib.optionalString withGmp gmpLdOpts} -Wl,-export-dynamic
#      gcc -o s7n nrepl.c s7.o -lnotcurses-core -lm -I. -ldl ${lib.optionalString withGmp gmpLdOpts}

      # Use the rpel to build *_s7.so libs.
      #   TODO: Make building *_s7.so libs more robust.
#      for lib in libc.scm libdl.scm libgdbm.scm libgsl.scm libm.scm libutf8proc.scm
      for lib in libc.scm libdl.scm
      do
        ./s7i $lib
      done

      # Build s7 as a shared library.
      gcc s7.c -shared -o ./libs7.so -fpic -O2 -g -ldl -lm ${lib.optionalString withGmp gmpLdOpts} -Wl,-export-dynamic
    '';

    installPhase = ''
      mkdir -p $out/s7 $out/bin $out/lib $out/include $out/man
      cp -r * $out/s7
#     ln -s $out/s7/s7{d,i,n} $out/bin
      ln -s $out/s7/s7{d,i} $out/bin
#      ln -s $out/s7/libs7.so $out/s7/lib{c,dl,gdbm,gsl,m}_s7.so $out/s7/utf8proc_s7.so $out/lib
      ln -s $out/s7/libs7.so $out/s7/lib{c,dl}_s7.so $out/lib
      ln -s $out/s7/s7.h $out/include
      cp -r ${s7-man}/man/* $out/man
    '';

    meta = with lib; {
      description = "s7 Scheme";
      homepage = https://ccrma.stanford.edu/software/s7/;
      downloadPage = https://cm-gitlab.stanford.edu/bil/s7;
      license = licenses.bsd0;
      maintainers = [ maintainers.patternspandemic ];
      platforms = [ "x86_64-linux" ];
    };
  }
