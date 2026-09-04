{inputs}: final: _prev: {
  unstablePkgs = import inputs.nixpkgs-unstable {
    inherit (final) system;
    config.allowUnfree = true;
  };
}
