{
  config,
  lib,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.shell.starship;
in
{
  options = {
    modules.shell.starship = with types; {
      enable = mkBoolOpt false;
    };
  };

  config = mkIf cfg.enable {
    hm = {
      programs.starship = {
        enable = true;

        enableZshIntegration = config.modules.shell.zsh.enable;
        enableFishIntegration = config.modules.shell.fish.enable;
        enableBashIntegration = false;

        # See docs at https://starship.rs/config
        # Symbols from nerd-font-symbols preset: `starship preset nerd-font-symbols`
        settings = {
          gcloud.disabled = true;

          aws.symbol = mkDefault " ";
          buf.symbol = mkDefault " ";
          bun.symbol = mkDefault " ";
          c.symbol = mkDefault " ";
          cmake.symbol = mkDefault " ";
          conda.symbol = mkDefault " ";
          cpp.symbol = mkDefault " ";
          crystal.symbol = mkDefault " ";
          dart.symbol = mkDefault " ";
          deno.symbol = mkDefault " ";
          directory.read_only = mkDefault " 󰌾";
          docker_context.symbol = mkDefault " ";
          dotnet.symbol = mkDefault " ";
          elixir.symbol = mkDefault " ";
          elm.symbol = mkDefault " ";
          erlang.symbol = mkDefault " ";
          fennel.symbol = mkDefault " ";
          fortran.symbol = mkDefault " ";
          fossil_branch.symbol = mkDefault " ";
          gcloud.symbol = mkDefault " ";
          git_branch.symbol = mkDefault " ";
          git_commit.tag_symbol = mkDefault " ";
          git_status.ahead = mkDefault " ";
          git_status.behind = mkDefault " ";
          git_status.conflicted = mkDefault " ";
          git_status.deleted = mkDefault " ";
          git_status.diverged = mkDefault " ";
          git_status.format = mkDefault "([$all_status$ahead_behind]($style) )";
          git_status.modified = mkDefault " ";
          git_status.renamed = mkDefault " ";
          git_status.staged = mkDefault " ";
          git_status.stashed = mkDefault " ";
          git_status.untracked = mkDefault " ";
          golang.symbol = mkDefault " ";
          gradle.symbol = mkDefault " ";
          guix_shell.symbol = mkDefault " ";
          haskell.symbol = mkDefault " ";
          haxe.symbol = mkDefault " ";
          helm.symbol = mkDefault "⎈ ";
          hg_branch.symbol = mkDefault " ";
          hostname.ssh_symbol = mkDefault " ";
          java.symbol = mkDefault " ";
          julia.symbol = mkDefault " ";
          kotlin.symbol = mkDefault " ";
          kubernetes.symbol = mkDefault "☸ ";
          lua.symbol = mkDefault " ";
          memory_usage.symbol = mkDefault "󰍛 ";
          meson.symbol = mkDefault "󰔷 ";
          nim.symbol = mkDefault "󰆥 ";
          nix_shell.symbol = mkDefault " ";
          nodejs.symbol = mkDefault " ";
          ocaml.symbol = mkDefault " ";
          openstack.symbol = mkDefault " ";
          package.symbol = mkDefault "󰏗 ";
          perl.symbol = mkDefault " ";
          php.symbol = mkDefault " ";
          pijul_channel.symbol = mkDefault " ";
          pixi.symbol = mkDefault "󰏗 ";
          purescript.symbol = mkDefault "<≡> ";
          python.symbol = mkDefault " ";
          rlang.symbol = mkDefault "󰟔 ";
          ruby.symbol = mkDefault " ";
          rust.symbol = mkDefault "󱘗 ";
          scala.symbol = mkDefault " ";
          shlvl.symbol = mkDefault " ";
          status.not_executable_symbol = mkDefault " ";
          status.not_found_symbol = mkDefault " ";
          status.sigint_symbol = mkDefault " ";
          status.signal_symbol = mkDefault " ";
          status.symbol = mkDefault " ";
          swift.symbol = mkDefault " ";
          terraform.symbol = mkDefault "𝗧 ";
          vagrant.symbol = mkDefault "𝗩 ";
          xmake.symbol = mkDefault " ";
          zig.symbol = mkDefault " ";
        };
      };
    };
  };
}
