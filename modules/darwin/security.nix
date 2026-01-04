{ ... }:

{
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true; # Enable Touch ID in tmux/screen via pam_reattach
  };
}
