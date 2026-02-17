{
  pkgs,
  ...
}:
{
  home.packages = [
    pkgs.aider-chat
    pkgs.claude-code
  ];
}
