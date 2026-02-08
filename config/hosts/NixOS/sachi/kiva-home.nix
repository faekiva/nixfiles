{
  pkgs,
  flakeRoot,
  personal-scripts,
  ...
}@args:
{
  home.stateVersion = "25.11";
  # home.packages  = with pkgs; [

  # ];

  imports = [
    "${flakeRoot}/modules/hereafter/hm/level1-packages.nix"
    "${flakeRoot}/modules/hereafter/hm/ai-packages.nix"
  ];

  # TODO: Import personal-scripts.homeManagerModules.default once infinite recursion is fixed
  # For now, we include the key configurations directly

  # Packages from personal-scripts
  home.packages = with pkgs; [
    # Core tools
    coreutils
    git

    # Modern CLI replacements
    lsd
    bat
    fd
    ripgrep
    delta  # git-delta
    sd

    # Shell utilities
    fzf
    gum
    jq
    htop
    httpie

    # Editors
    micro

    # Languages & runtimes
    go
    python313
    bun

    # Task runners
    go-task

    # Other
    eget
    mods  # charmbracelet mods
    autojump

    # Fonts (for GUI systems)
    nerd-fonts.hack
  ];

  # Git configuration from personal-scripts
  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
      diff = {
        algorithm = "histogram";
        colorMoved = "plain";
        mnemonicPrefix = true;
        renames = true;
      };
      fetch = {
        prune = true;
        pruneTags = true;
        all = true;
      };
      column.ui = "auto";
      branch.sort = "-committerdate";
      tag.sort = "version:refname";
      commit.verbose = true;
      rerere = {
        enabled = true;
        autoupdate = true;
      };
      advice.skippedCherryPicks = false;
      bash = {
        enableGitStatus = true;
        enableFileStatus = true;
        showStatusWhenZero = false;
        enableStashStatus = true;
        enableStatusSymbol = true;
      };
      alias = {
        c = "checkout";
        po = "push -u origin HEAD";
        diffc = "diff --cached";
      };
    };
  };

  # Delta configuration for git
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      features = "decorations";
      side-by-side = true;
      navigate = true;
      line-numbers = true;
      hyperlinks = true;
      hyperlinks-file-link-format = "vscode://file/{path}:{line}";
      interactive = {
        keep-plus-minus-markers = false;
      };
      decorations = {
        commit-decoration-style = "blue ol";
        commit-style = "raw";
        file-style = "omit";
        hunk-header-decoration-style = "blue box";
        hunk-header-file-style = "red";
        hunk-header-line-number-style = "#067a00";
        hunk-header-style = "file line-number syntax";
      };
    };
  };

  # Direnv configuration
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };
}
