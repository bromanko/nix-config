{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.shell.git;
in {
  options.modules.shell.git = { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    home-manager.users."${config.user.name}" = {
      home.packages = [ pkgs.git pkgs.gh ];

      programs.zsh.shellAliases = mkIf config.modules.shell.zsh.enable {
        g = "git";
        ga = "git add";
        gb = "git branch";
        gc = "git commit";
        gcm = "git checkout main";
        gco = "git checkout";
        gcp = "git cherry-pick";
        gd = "git diff";
        ggpush = "git push origin $(current_branch)";
        gl = "git pull --prune";
        gp = "git push origin HEAD";
        gs = "git status -sb";
      };

    };
  };
}