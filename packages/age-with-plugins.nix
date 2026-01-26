{ pkgs, lib, ... }:

pkgs.writeShellApplication {
  name = "age";
  runtimeInputs = with pkgs; [
    my.age-plugin-op
    _1password-cli
  ];
  text = ''
    ${pkgs.age}/bin/age "$@"
  '';
  meta = with lib; {
    description = "age encryption tool with 1Password plugin support";
    homepage = "https://github.com/FiloSottile/age";
    license = licenses.bsd3;
    platforms = platforms.all;
  };
}
