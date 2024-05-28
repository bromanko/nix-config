{ lib, ... }:

with lib;
with lib.my; {
  options.modules.term.kitty = with types; {
    enable = mkBoolOpt false;
    fontSize = mkOption {
      type = int;
      example = "16";
      description = "The size of the font.";
      default = 14;
    };
  };
}
