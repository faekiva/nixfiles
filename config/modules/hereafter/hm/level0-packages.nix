{
  pkgs,
  ...
}:
{
  home.packages = [ 
    pkgs.htop
    pkgs.busybox
    pkgs.fd
    pkgs.git
    pkgs.micro
  ];
}
