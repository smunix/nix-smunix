{
  lib,
  mapFilterAttrs,
}: let
  inherit (builtins) attrValues concatLists pathExists readDir;
  inherit (lib.attrsets) filterAttrs mapAttrsToList nameValuePair;
  inherit (lib.strings) hasPrefix hasSuffix removeSuffix;
  inherit (lib.trivial) id;
in rec {
  mapModules = dir: transform:
    mapFilterAttrs
    (_name: value: value != null)
    (
      name: type: let
        path = "${toString dir}/${name}";
      in
        if hasPrefix "_" name
        then nameValuePair "" null
        else if type == "directory" && pathExists "${path}/default.nix"
        then nameValuePair name (transform path)
        else if type == "regular" && name != "default.nix" && hasSuffix ".nix" name
        then nameValuePair (removeSuffix ".nix" name) (transform path)
        else nameValuePair "" null
    )
    (readDir dir);

  mapModules' = dir: transform:
    attrValues (mapModules dir transform);

  mapModulesRec = dir: transform:
    mapFilterAttrs
    (_name: value: value != null)
    (
      name: type: let
        path = "${toString dir}/${name}";
      in
        if hasPrefix "_" name
        then nameValuePair "" null
        else if type == "directory"
        then nameValuePair name (mapModulesRec path transform)
        else if type == "regular" && name != "default.nix" && hasSuffix ".nix" name
        then nameValuePair (removeSuffix ".nix" name) (transform path)
        else nameValuePair "" null
    )
    (readDir dir);

  mapModulesRec' = dir: transform: let
    directories =
      mapAttrsToList
      (name: _type: "${toString dir}/${name}")
      (filterAttrs (name: type: type == "directory" && !(hasPrefix "_" name)) (readDir dir));
    files = attrValues (mapModules dir id);
  in
    map transform (files ++ concatLists (map (path: mapModulesRec' path id) directories));
}
