{
  lib,
  pkgs,
  ...
}:
{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = lib.mkDefault "kiva";
        email = lib.mkDefault "git@kiva.lgbt";
      };

      alias = {
        c = "checkout";
        po = "push -u origin HEAD";
        diffc = "diff --cached";
      };

      init.defaultBranch = "main";

      column.ui = "auto";
      branch.sort = "-committerdate";
      tag.sort = "version:refname";

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

      pull.rebase = true;

      commit.verbose = true;
      rerere = {
        enabled = true;
        autoupdate = true;
      };

      advice.skippedCherryPicks = false;

      # posh-git-sh style settings
      bash = {
        enableGitStatus = true;
        enableFileStatus = true;
        showStatusWhenZero = false;
        enableStashStatus = true;
        enableStatusSymbol = true;
      };
    };

    ignores = [
      ".jj"
      "vault.json"
    ];
  };

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
}
