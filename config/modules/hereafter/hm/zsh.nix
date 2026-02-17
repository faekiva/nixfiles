{
  inputs,
  ...
}:
{
  programs.zsh = {
    enable = true;

    # Nix-managed plugins
    plugins = [
      {
        name = "fzf-tab";
        src = inputs.fzf-tab;
      }
    ];

    # Gradually migrate your config here
    initExtra = ''
      # direnv-instant (already migrated!)
      eval "$(${inputs.direnv-instant}/bin/direnv-instant hook zsh)"

      # Source your existing manual config during transition
      # TODO: Gradually move sections from this file into proper nix options above
      if [ -f "$HOME/code/no-remote/dotfiles-local/.zshrc" ]; then
        source "$HOME/code/no-remote/dotfiles-local/.zshrc"
      fi
    '';
  };
}
# programs.zsh.initContent

# Content to be added to .zshrc.

# To specify the order, use lib.mkOrder.

# Common order values:

#     500 (mkBefore): Early initialization (replaces initExtraFirst)
#     550: Before completion initialization (replaces initExtraBeforeCompInit)
#     1000 (default): General configuration (replaces initExtra)
#     1500 (mkAfter): Last to run configuration

# To specify both content in Early initialization and General configuration, use lib.mkMerge.

# e.g.

# initContent = let zshConfigEarlyInit = lib.mkOrder 500 "do something"; zshConfig = lib.mkOrder 1000 "do something"; in lib.mkMerge [ zshConfigEarlyInit zshConfig ];