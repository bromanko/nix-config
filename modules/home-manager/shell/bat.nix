{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.shell.bat;
  shellAliases = {
    cat = "${pkgs.bat}/bin/bat";
    "cat!" = "command cat";
  };
in
{
  options.modules.shell.bat = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hm = {
      programs.bat = {
        enable = true;
        config = {
          theme = "catppuccin-mocha";
        };
        themes = {
          catppuccin-mocha = {
            src = pkgs.fetchFromGitHub {
              owner = "catppuccin";
              repo = "bat"; # Bat uses sublime syntax for its themes
              rev = "699f60fc8ec434574ca7451b444b880430319941";
              sha256 = "sha256-6fWoCH90IGumAMc4buLRWL0N61op+AuMNN9CAR9/OdI=";
            };
            file = "themes/Catppuccin Mocha.tmTheme";
          };
        };
      };

      programs.zsh.shellAliases = mkIf config.modules.shell.zsh.enable shellAliases;

      # For fish, use a function that falls back to real cat for binary files
      programs.fish = mkIf config.modules.shell.fish.enable {
        functions.cat = ''
          # Check if file exists and is a regular file
          if test -f $argv[1]
            # Use file command to detect binary files
            if file -b --mime $argv[1] 2>/dev/null | grep -q '^text/'
              # Text file - use bat
              ${pkgs.bat}/bin/bat $argv
            else
              # Binary file or unable to detect - use real cat
              command cat $argv
            end
          else
            # Not a file (stdin, directory, etc) - use bat
            ${pkgs.bat}/bin/bat $argv
          end
        '';
        shellAliases."cat!" = "command cat";
      };
    };
  };
}
