{ pkgs, ... }:

pkgs.writeShellApplication {
  name = "age";
  runtimeInputs = with pkgs; [ my.age-plugin-op _1password ];
  text = ''
    ${pkgs.age}/bin/age "$@"
  '';
}
