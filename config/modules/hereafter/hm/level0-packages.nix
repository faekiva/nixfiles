{
  pkgs,
  lib,
  ...
}:
{
  home.packages = [
    pkgs.htop
    pkgs.fd
    pkgs.git
    pkgs.micro
  ] ++ lib.optional pkgs.stdenv.isLinux pkgs.busybox;
}
