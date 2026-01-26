{
  config,
  options,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.desktop.chromium;
in
{
  options.modules.desktop.chromium = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    home-manager.users."${config.user.name}".home.packages = [ pkgs.chromium ];

    programs.chromium = {
      enable = true;
      defaultSearchProviderSearchURL = "https://duckduckgo.com/?q={searchTerms}";
      defaultSearchProviderSuggestURL = "https://ac.duckduckgo.com/ac/?q={searchTerms}&type=list";
      extensions = [
        "gcbommkclmclpchllfjekcdonpmejbdp" # https everywhere
        "gbmdgpbipfallnflgajpaliibnhdgobh" # json viewer
        "mphdppdgoagghpmmhodmfajjlloijnbd" # pinboard plus
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock origin
        "hfjbmagddngcpeloejdejnfgbamkjaeg" # vimium c
      ];
    };
  };
}
