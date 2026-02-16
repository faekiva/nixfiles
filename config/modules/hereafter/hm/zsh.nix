{
  pkgs,
  ...
}:
{
  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "fzf-tab" ];
    };
    initExtra = ''
      eval "$(direnv-instant hook zsh)"
    '';
  };
}
