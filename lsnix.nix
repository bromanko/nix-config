with builtins;

# Create a list of all nix files in a folder
let
  nixName = name: type:
    if type == "regular" then name else "${name}/default.nix";
  namedDotNix = name: builtins.match ".*\\.nix" name != null;
  asPaths = dir: map (x: dir + "/${x}");
in dir:
filter pathExists
(asPaths dir (filter namedDotNix (attrValues (mapAttrs nixName (readDir dir)))))
