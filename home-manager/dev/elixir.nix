{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.dev.elixir;
in {
  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [ elixir_ls ];
      file.".iex.exs".source = ../../configs/elixir/iex.exs;
    };

    programs.zsh.shellAliases = {
      iex = ''iex --erl "-kernel shell_history enabled"'';
    };
  };
}
