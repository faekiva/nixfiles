{
  pkgs,
  ...
}:
{
  programs.atuin = {
    enable = true;
    forceOverwriteSettings = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableNushellIntegration = true;
    settings = {
      auto_sync = true;
      sync_frequency = "5m";
      sync_address = "https://api.atuin.sh";
      filter_mode_shell_up_key_binding = "directory";
      style = "compact";
      inline_height = 20;
      enter_accept = true;
      sync.records = true;
      search_mode = "fuzzy";
    };
    
  };
}
