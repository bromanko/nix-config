{
  config,
  options,
  lib,
  pkgs,
  ...
}:

{
  users.users.${config.user.name} = {
    home = "/Users/${config.user.name}";
  };
}
