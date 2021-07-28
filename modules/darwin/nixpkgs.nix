{ config, ... }:

{
  nixpkgs = { config.allowUnfree = true; };
}
