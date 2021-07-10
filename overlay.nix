{ s7-src }:
final: prev:
{
  # TODO: Provide different versions of s7, e.g. without gmp, pure s7, etc.
  s7 = prev.callPackage ./s7 { inherit s7-src; };
  # libs7 = prev.callPackage ./s7/lib.nix {};
}
