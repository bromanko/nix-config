{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.homebrew;
  enabled = cfg.enable && pkgs.stdenv.hostPlatform.isDarwin;
in
{
  options.modules.homebrew = with types; {
    enable = mkBoolOpt false;

    prefix = mkOption {
      type = str;
      default = "/usr/local";
      description = ''
        The Homebrew prefix directory, matching the output of `brew --prefix`.
      '';
    };

    taps = mkOption {
      type = listOf (oneOf [
        str
        attrs
      ]);
      default = [ ];
      example = [
        "homebrew/cask-versions"
        {
          name = "user/tap-repo";
          clone_target = "https://user@bitbucket.org/user/homebrew-tap-repo.git";
          force_auto_update = true;
        }
      ];
      description = "Homebrew formula repositories to tap (string or tap attrset).";
    };

    brews = mkOption {
      type = with types; listOf str;
      default = [ ];
      example = [ "mas" ];
      description = "Homebrew brews to install.";
    };

    casks = mkOption {
      type = with types; listOf str;
      default = [ ];
      example = [
        "hammerspoon"
        "virtualbox"
      ];
      description = "Homebrew casks to install.";
    };

    masApps = mkOption {
      type = with types; attrsOf ints.positive;
      default = { };
      example = {
        "1Password" = 1107421413;
        Xcode = 497799835;
      };
      description = ''
        Applications to install from Mac App Store using <command>mas</command>.
        When this option is used, <literal>"mas"</literal> is automatically added to
        <option>homebrew.brews</option>.
        Note that you need to be signed into the Mac App Store for <command>mas</command> to
        successfully install and upgrade applications, and that unfortunately apps removed from this
        option will not be uninstalled automatically even if
        <option>homebrew.cleanup</option> is set to <literal>"uninstall"</literal>
        or <literal>"zap"</literal> (this is currently a limitation of Homebrew Bundle).
        For more information on <command>mas</command> see: https://github.com/mas-cli/mas.
      '';
    };
  };

  config = mkIf enabled {
    home-manager.users."${config.user.name}".home = {
      packages = with pkgs; [ m-cli ];
    };

    homebrew = {
      enable = true;
      onActivation = {
        autoUpdate = true;
        cleanup = "zap";
      };
      global = {
        brewfile = true;
      };

      prefix = cfg.prefix;
      taps = cfg.taps;
      brews = cfg.brews;
      casks = cfg.casks;
      masApps = cfg.masApps;
    };
  };
}
