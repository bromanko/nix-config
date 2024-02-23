{ pkgs, ... }:

pkgs.writeShellApplication {
  name = "age";
  runtimeInputs = [ pkgs.my.age-plugin-op ];
  text = ''
    ${pkgs.age}/bin/age "$@"
  '';
}
