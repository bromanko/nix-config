{
  config,
  lib,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.desktop.apps."1Password";
in
{
  options.modules.desktop.apps."1Password" = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    modules = {
      # Install desktop app via homebrew
      homebrew.casks = [ "1password" ];

      # Enable CLI and configuration
      shell."1password".enable = true;
    };
  };
}
