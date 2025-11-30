{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.shell.git;
  shellAliases = {
    g = "git";
    ga = "git add";
    gb = "git branch";
    gc = "git commit";
    gcm = "git checkout main";
    gco = "git checkout";
    gcp = "git cherry-pick";
    gd = "git diff";
    ggpush = "git push origin $(current_branch)";
    gl = "git pull --prune";
    gp = "git push origin HEAD";
    gs = "git status -sb";
  };
in
{
  config = mkIf cfg.enable {
    hm = {
      programs.git = {
        enable = true;

        settings = {
          user = {
            email = cfg.userEmail;
            name = cfg.userName;
          };

          init = {
            defaultBranch = "main";
          };

          core = {
            whitespace = "trailing-space";
            fsmonitor = true;
            untrackedCache = true;
          };

          github = {
            user = cfg.gitHubUser;
          };

          rebase = {
            autosquash = true;
          };

          push = {
            default = "current";
          };

          pull = {
            default = "current";
            rebase = true;
          };

          apply = {
            whitespace = "nowarn";
          };

          rerere = {
            enabled = true;
            autoupdate = true;
          };

          githooks = {
            cloneUrl = "https://github.com/rycus86/githooks.git";
            cloneBranch = "master";
            useCoreHooksPath = false;
          };

          "diff \"sopsdiffer\"" = {
            textconv = "sops -d";
          };

          alias = {
            # Basics
            st = "status -sb";
            cl = "clone";
            ci = "commit";
            co = "checkout";
            br = "branch";
            r = "reset";
            cp = "cherry-pick";
            gr = "grep -Ii";

            # Tweak defaults
            diff = "diff --word-diff";
            branch = "branch -ra";
            grep = "grep -Ii";
            bra = "branch -ra";
            ai = "add --interactive";

            # Commit
            cm = "commit -m";
            cma = "commit -a -m";
            ca = "commit --amend";
            amend = "commit --amend";
            caa = "commit -a --amend -C HEAD";

            # Log
            ls = ''log --pretty=format:"%C(green)%h\\ %C(yellow)[%ad]%Cred%d\\ %Creset%s%Cblue\\ [%an]" --decorate --date=relative'';
            ll = ''log --pretty=format:"%C(yellow)%h%Cred%d\\ %Creset%s%Cblue\\ [a:%an,c:%cn]" --decorate --numstat'';
            lc = ''"!f() { git ll "$1"^.."$1"; }; f"'';
            lnc = ''log --pretty=format:"%h\\ %s\\ [%cn]"'';
            fl = "log -u";
            filelog = "log -u";

            # Diff
            d = "diff --word-diff";
            dc = "diff --cached";

            # Diff last commit
            dlc = "diff --cached HEAD^";
            dr = ''"!f() { git diff -w "$1"^.."$1"; }; f"'';
            diffr = ''"!f() { git diff "$1"^.."$1"; }; f"'';

            # Reset
            r1 = "reset HEAD^";
            r2 = "reset HEAD^^";
            rh = "reset --hard";
            rh1 = "reset HEAD^ --hard";
            rh2 = "reset HEAD^^ --hard";

            # Stash
            sl = "stash list";
            sa = "stash apply";
            ss = "stash save";

            # Conflict/merges
            ours = ''"!f() { git co --ours $@ && git add $@; }; f"'';
            theirs = ''"!f() { git co --theirs $@ && git add $@; }; f"'';

            # List remotes
            rem = ''"!git config -l | grep remote.*url | tail -n +2"'';

            # Initial empty commit
            empty = ''"!git commit -am\"[empty] Initial commit\" --allow-empty"'';

            # List all aliases
            la = ''"!git config -l | grep alias | cut -c 7-"'';

            # Plugins
            hooks = ''!sh \"$HOME/.githooks/release/cli.sh\"'';
          };
        };

        ignores = [
          "*~"
          "*.*~"
          "#*"
          ".#*"
          "*.swp"
          "*.*.sw[a-z]"
          "*.un~"
          ".DS_Store?"
          ".DS_Store"
          ".Trash"
        ];
      };

      programs.delta = {
        enable = true;
        enableGitIntegration = true;
        options = {
          features = "decorations";
          side-by-side = true;
          syntax-theme = "Monokai Extended";
        };
      };

      programs.gh = {
        enable = true;
        settings = {
          git_protocol = "ssh";
        };
      };

      programs.zsh.shellAliases = mkIf config.modules.shell.zsh.enable shellAliases;
      programs.fish.shellAliases = mkIf config.modules.shell.fish.enable shellAliases;
    };
  };

  options.modules.shell.git = {
    enable = mkBoolOpt false;

    userEmail = mkOption {
      type = types.str;
      default = "hello@bromanko.com";
    };

    userName = mkOption {
      type = types.str;
      default = "Brian Romanko";
    };

    gitHubUser = mkOption {
      type = types.str;
      default = "bromanko";
    };
  };
}
