{lib}: {
  mapFilterAttrs = predicate: transform: attrs:
    lib.filterAttrs predicate (lib.mapAttrs' transform attrs);
}
