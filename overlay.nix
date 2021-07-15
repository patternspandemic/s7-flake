{ s7-src, s7-man }:
final: prev:
{
  # TODO: Provide different versions of s7, e.g. without gmp, pure s7, etc.
  s7 = prev.callPackage ./s7 { inherit s7-src s7-man; };
  # libs7 = prev.callPackage ./s7/lib.nix {};
}
