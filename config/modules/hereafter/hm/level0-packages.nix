{
  pkgs,
  lib,
  ...
}:
{
  imports =  [ ./comma.nix ];

  home.packages = [
    pkgs.htop
    pkgs.fd
    pkgs.git
    pkgs.nil
    pkgs.micro
    pkgs.curl
  ] ++ lib.optional pkgs.stdenv.isLinux pkgs.busybox;
}
