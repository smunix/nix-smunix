_: final: prev: let
  ndi6 = prev."ndi-6".overrideAttrs (old: {
    src = final.fetchurl {
      inherit (old.src) urls;
      hash = "sha256-8DFPJFRG3vxIi2POtGiazxqWWu79ray3BXG7IWqMwYM=";
    };
  });
  distroav = prev.obs-studio-plugins.distroav.override {
    ndi-6 = ndi6;
  };
in {
  ndi-6 = ndi6;

  obs-studio-plugins =
    prev.obs-studio-plugins
    // {
      inherit distroav;

      # DistroAV is the current upstream name for the plugin formerly
      # packaged as obs-ndi.
      obs-ndi = distroav;
    };
}
