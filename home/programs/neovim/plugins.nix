{ pkgs, ... }:

{
  sonokai-vim = pkgs.vimUtils.buildVimPlugin {
    name = "sonokai-vim";
    src = pkgs.fetchFromGitHub {
      owner = "sainnhe";
      repo = "sonokai";
      rev = "78f1b14ad18b043eb888a173f4c431dbf79462d8";
      sha256 = "YMeW9dYJKBwcCX4yyHwpmAsiqmv+Ma6uTE2Rg/K/9mo=";
    };
  };
}
