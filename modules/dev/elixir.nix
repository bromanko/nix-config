{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.dev.elixir;
in {
  options.modules.dev.elixir = with types; { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    home-manager.users."${config.user.name}" = {
      home = {
        packages = with pkgs; [ elixir_ls ];
        file.".iex.exs".source = ../../configs/elixir/iex.exs;
      };

      programs.zsh.shellAliases = {
        iex = ''iex --erl "-kernal shell_history enabled"'';
      };
    };
  };
}
