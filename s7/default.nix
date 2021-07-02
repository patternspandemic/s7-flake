### TODO
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
, haveComplexNumbers ? true
, haveComplexTrig ? true
, withGmp ? true
, s7Debugging ? false
, withMultithreadChecks ? false
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
      #define HAVE_COMPLEX_NUMBERS ${toDefineVal haveComplexNumbers}
      #define HAVE_COMPLEX_TRIG ${toDefineVal haveComplexTrig}
      #define WITH_GMP ${toDefineVal withGmp}
      #define WITH_MULTITHREAD_CHECKS ${toDefineVal withMultithreadChecks}
      #define S7_DEBUGGING ${toDefineVal s7Debugging}
      #define S7_LOAD_PATH "${builtins.placeholder "out"}/s7"
      EOF

      # Build the dumb repl.
      gcc s7.c -o s7d -DWITH_MAIN -DWITH_C_LOADER=0 -I. -O2 -g -ldl -lm ${lib.optionalString withGmp gmpLdOpts} -Wl,-export-dynamic
      
      # Build the repl with the c loader.
      gcc s7.c -o s7i -DWITH_MAIN -I. -O2 -g -ldl -lm ${lib.optionalString withGmp gmpLdOpts} -Wl,-export-dynamic
      
      # Build the notcurses repl.
      gcc -o s7n s7.c -DWITH_MAIN -DWITH_NOTCURSES -O2 -I. -lm -ldl -lnotcurses-core ${lib.optionalString withGmp gmpLdOpts} -Wl,-export-dynamic

      # Use the rpel to build *_s7.so libs.
      #   TODO: Make building *_s7.so libs more robust.
      for lib in libc.scm libdl.scm libgdbm.scm libgsl.scm libm.scm libutf8proc.scm
      do
        ./s7i $lib
      done

      # TODO: Try to build s7.so
    '';

    installPhase = ''
      mkdir -p $out/s7 $out/bin $out/lib $out/include
      cp -r * $out/s7
      ln -s $out/s7/s7{d,i,n} $out/bin
      ln -s $out/s7/lib{c,dl,gdbm,gsl,m}_s7.so $out/s7/utf8proc_s7.so $out/lib
      ln -s $out/s7/s7.h $out/include
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
