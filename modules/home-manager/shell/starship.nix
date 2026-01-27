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
          buf.format = mkDefault "with [$symbol]($style)";
          buf.symbol = mkDefault " ";
          bun.format = mkDefault "via [$symbol]($style)";
          bun.symbol = mkDefault " ";
          c.format = mkDefault "via [$symbol($name)]($style)";
          c.symbol = mkDefault " ";
          cmake.format = mkDefault "via [$symbol]($style)";
          cmake.symbol = mkDefault " ";
          conda.symbol = mkDefault " ";
          cpp.format = mkDefault "via [$symbol($name)]($style)";
          cpp.symbol = mkDefault " ";
          crystal.format = mkDefault "via [$symbol]($style)";
          crystal.symbol = mkDefault " ";
          dart.format = mkDefault "via [$symbol]($style)";
          dart.symbol = mkDefault " ";
          deno.format = mkDefault "via [$symbol]($style)";
          deno.symbol = mkDefault " ";
          directory.read_only = mkDefault " 󰌾";
          docker_context.symbol = mkDefault " ";
          dotnet.format = mkDefault "[$symbol(🎯 $tfm )]($style)";
          dotnet.symbol = mkDefault " ";
          elixir.format = mkDefault "via [$symbol]($style)";
          elixir.symbol = mkDefault " ";
          elm.format = mkDefault "via [$symbol]($style)";
          elm.symbol = mkDefault " ";
          erlang.format = mkDefault "via [$symbol]($style)";
          erlang.symbol = mkDefault " ";
          fennel.format = mkDefault "via [$symbol]($style)";
          fennel.symbol = mkDefault " ";
          fortran.format = mkDefault "via [$symbol]($style)";
          fortran.symbol = mkDefault " ";
          fossil_branch.symbol = mkDefault " ";
          gcloud.symbol = mkDefault " ";
          git_branch.symbol = mkDefault " ";
          git_branch.disabled = true;

          # Jujutsu support (custom module)
          custom.jj = {
            command = "jj log -r @ --no-graph --color=always -T 'change_id.shortest(8)'";
            when = "test -d .jj";
            symbol = "◇ ";
            style = "bold purple";
            format = "[$symbol]($style)$output ";
          };
          git_commit.disabled = true;
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
          golang.format = mkDefault "via [$symbol]($style)";
          golang.symbol = mkDefault " ";
          gradle.format = mkDefault "via [$symbol]($style)";
          gradle.symbol = mkDefault " ";
          guix_shell.symbol = mkDefault " ";
          haskell.format = mkDefault "via [$symbol]($style)";
          haskell.symbol = mkDefault " ";
          haxe.format = mkDefault "via [$symbol]($style)";
          haxe.symbol = mkDefault " ";
          helm.format = mkDefault "via [$symbol]($style)";
          helm.symbol = mkDefault "⎈ ";
          hg_branch.symbol = mkDefault " ";
          hostname.ssh_symbol = mkDefault " ";
          java.format = mkDefault "via [$symbol]($style)";
          java.symbol = mkDefault " ";
          julia.format = mkDefault "via [$symbol]($style)";
          julia.symbol = mkDefault " ";
          kotlin.format = mkDefault "via [$symbol]($style)";
          kotlin.symbol = mkDefault " ";
          kubernetes.symbol = mkDefault "☸ ";
          lua.format = mkDefault "via [$symbol]($style)";
          lua.symbol = mkDefault " ";
          memory_usage.symbol = mkDefault "󰍛 ";
          meson.format = mkDefault "via [$symbol]($style)";
          meson.symbol = mkDefault "󰔷 ";
          nim.format = mkDefault "via [$symbol]($style)";
          nim.symbol = mkDefault "󰆥 ";
          nix_shell.symbol = mkDefault " ";
          nodejs.format = mkDefault "via [$symbol]($style)";
          nodejs.symbol = mkDefault " ";
          ocaml.format = mkDefault "via [$symbol(\($switch_indicator$switch_name\) )]($style)";
          ocaml.symbol = mkDefault " ";
          openstack.symbol = mkDefault " ";
          package.symbol = mkDefault "󰏗 ";
          perl.format = mkDefault "via [$symbol]($style)";
          perl.symbol = mkDefault " ";
          php.format = mkDefault "via [$symbol]($style)";
          php.symbol = mkDefault " ";
          pijul_channel.symbol = mkDefault " ";
          pixi.format = mkDefault "via [$symbol($environment )]($style)";
          pixi.symbol = mkDefault "󰏗 ";
          purescript.format = mkDefault "via [$symbol]($style)";
          purescript.symbol = mkDefault "<≡> ";
          python.format = mkDefault "via [$symbol]($style)";
          python.symbol = mkDefault " ";
          rlang.format = mkDefault "via [$symbol]($style)";
          rlang.symbol = mkDefault "󰟔 ";
          ruby.format = mkDefault "via [$symbol]($style)";
          ruby.symbol = mkDefault " ";
          rust.format = mkDefault "via [$symbol]($style)";
          rust.symbol = mkDefault "󱘗 ";
          scala.format = mkDefault "via [$symbol]($style)";
          scala.symbol = mkDefault " ";
          shlvl.symbol = mkDefault " ";
          status.not_executable_symbol = mkDefault " ";
          status.not_found_symbol = mkDefault " ";
          status.sigint_symbol = mkDefault " ";
          status.signal_symbol = mkDefault " ";
          status.symbol = mkDefault " ";
          swift.format = mkDefault "via [$symbol]($style)";
          swift.symbol = mkDefault " ";
          terraform.symbol = mkDefault "𝗧 ";
          vagrant.format = mkDefault "via [$symbol]($style)";
          vagrant.symbol = mkDefault "𝗩 ";
          xmake.format = mkDefault "via [$symbol]($style)";
          xmake.symbol = mkDefault " ";
          zig.format = mkDefault "via [$symbol]($style)";
          zig.symbol = mkDefault " ";
        };
      };
    };
  };
}

# This won't work - need to add inside settings block
