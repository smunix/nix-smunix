_: _final: prev: {
  obs-studio-plugins =
    prev.obs-studio-plugins
    // {
      # DistroAV is the current upstream name for the plugin formerly
      # packaged as obs-ndi.
      obs-ndi = prev.obs-studio-plugins.distroav;
    };
}
