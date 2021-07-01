{ s7-src }:
final: prev:
{
  s7 = prev.callPackage ./s7 { inherit s7-src; };
  # libs7 = prev.callPackage    ./s7 { inherit s7-src; build = "lib"; };
  # s7-repl = prev.callPackage  ./s7 { inherit s7-src; build = "repl"; };
}
