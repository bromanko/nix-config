{
  config,
  pkgs,
  ...
}:

{
  users.users.${config.user.name} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    home = "/home/${config.user.name}";
    shell = pkgs.fish;
    openssh = {
      authorizedKeys.keys = config.authorizedKeys;
    };
  };
}
