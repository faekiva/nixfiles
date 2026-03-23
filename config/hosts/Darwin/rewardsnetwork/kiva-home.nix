{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  hasPackage = pkg: builtins.elem pkg config.home.packages;
  hasAstGrep = hasPackage pkgs.ast-grep;
  hasClaude = hasPackage inputs.llm-agents.packages.${pkgs.system}.claude-code;
in
{
  home.stateVersion = "25.11";
  imports = [
    "${inputs.flakeRoot}/modules/hereafter/hm/level1-packages.nix"
    "${inputs.flakeRoot}/modules/hereafter/hm/ai-packages.nix"
  ];
  home.packages = [
  	pkgs.nickel
  	pkgs.ast-grep
  ];
  home.file.".claude/skills/ast-grep" = lib.mkIf (hasAstGrep && hasClaude) {
    source =
      pkgs.fetchFromGitHub {
        owner = "ast-grep";
        repo = "agent-skill";
        rev = "577f4d4507678f2c8cee150fae25e6ce309f70b1";
        hash = "sha256-LgGFtPieyKtoru22AhHW8hvkJ8kCHO2Cr8rBOWGuxvY=";
      }
      + "/ast-grep/skills/ast-grep";
  };
}
