{ lib, ... }:

with builtins;
with lib;
rec {
  # attrsToList
  attrsToList = attrs: mapAttrsToList (name: value: { inherit name value; }) attrs;

  # mapFilterAttrs ::
  #   (name -> value -> bool)
  #   (name -> value -> { name = any; value = any; })
  #   attrs
  mapFilterAttrs =
    pred: f: attrs:
    filterAttrs pred (mapAttrs' f attrs);
}
