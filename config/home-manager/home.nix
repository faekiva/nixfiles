{ pkgs, lib, home, ... }: {
  home.stateVersion = "25.11";
  home.packages = [pkgs.httpie];
}