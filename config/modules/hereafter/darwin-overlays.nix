{ ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      kvazaar = prev.kvazaar.overrideAttrs (_: { doCheck = false; });
      chromaprint = prev.chromaprint.overrideAttrs (_: { doCheck = false; });
    })
  ];
}
