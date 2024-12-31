{ pkgs, ... }:

pkgs.writeShellApplication {
  name = "age";
  runtimeInputs = with pkgs; [
    my.age-plugin-op
    _1password-cli
  ];
  text = ''
    ${pkgs.age}/bin/age "$@"
  '';
}
