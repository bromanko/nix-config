{
  pkgs,
  lib,
  ...
}:

pkgs.writeShellApplication {
  name = "tmux-dashboard";
  runtimeInputs = with pkgs; [
    tmux
    fzf
    jujutsu
    git
    coreutils
    gnugrep
  ];
  text = builtins.readFile ./tmux-dashboard/tmux-dashboard.sh;
  meta = with lib; {
    description = "Interactive tmux session picker with VCS and agent status";
    license = licenses.mit;
    platforms = platforms.all;
    mainProgram = "tmux-dashboard";
  };
}
