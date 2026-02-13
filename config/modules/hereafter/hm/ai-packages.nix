{
  pkgs,
  flakeRoot,
  ...
}:
{
  home.packages = [
    pkgs.aider-chat
    pkgs.claude-code
  ];
}
