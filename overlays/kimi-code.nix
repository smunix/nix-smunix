{inputs}: final: _prev: {
  kimi-code = inputs.kimi-code.packages.${final.stdenv.hostPlatform.system}.default;
}
