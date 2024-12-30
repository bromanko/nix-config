{ pkgs, ... }:

pkgs.writeShellApplication {
  name = "age";
  text = ''
    ${pkgs.age}/bin/age "$@"
  '';
}
