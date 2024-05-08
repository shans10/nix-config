# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # You can import other home-manager modules here
  imports = [
    # If you want to use home-manager modules from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModule

    # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # If you want to use overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = _: true;
    };
  };

  nix = {
    package = pkgs.nix;
    gc = {
      automatic = true;
      options = "--delete-older-than 3d";
    };
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
      warn-dirty = false;
    };
  };

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home = {
    username = "shan";
    homeDirectory = "/var/home/shan";

    # Install packages
    packages = with pkgs; [
      # Fonts
      (nerdfonts.override { fonts = [ "FiraCode" ]; })

      # CLI tools
      chezmoi
      eza
      fish
      fzf
      gcc
      starship
      nsxiv
      wl-clipboard
      zoxide
    ];

    # Extra configuration
    activation = with lib; {
      # Some software requires fonts to be present in $XDG_DATA_HOME/fonts in
      # order to use/see them (like Emacs, Flatpak), so just link to them.
      setupFonts = hm.dag.entryAfter [ "writeBoundary" ] ''
        fontsdir="${config.home.profileDirectory}/share/fonts"
        userfontsdir="${config.xdg.dataHome}/fonts"

        # create 'userfontsdir' if it doesn't exist
        if ! [ -d "${config.xdg.dataHome}/fonts" ]; then
          $DRY_RUN_CMD mkdir $userfontsdir
        fi

        # remove dead symlinks due to uninstalled font (e.g. all opentype fonts
        # are gone, leading to a broken link), etc.
        $DRY_RUN_CMD find $userfontsdir -xtype l \
          -exec echo unlinking {} \; -exec unlink {} \;

        # force necessary because of the many different fonts in colliding
        # directories
        for dir in $fontsdir/*; do
          $DRY_RUN_CMD unlink \
            $userfontsdir/$(basename $dir) 2>/dev/null || true
          $DRY_RUN_CMD ln -sf $VERBOSE_ARG \
            $dir $userfontsdir/$(basename $dir)
        done
      '';
    };

    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    #
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    stateVersion = "23.11"; # Please read the comment before changing.
  };

  # Configure programs
  programs = {
    # Let Home Manager install and manage itself.
    home-manager.enable = true;

    # Configure git
    # git = {
    #   enable = true;
    #   userName = "Shantanu Shukla";
    #   userEmail = "shantanu.shukla10@gmail.com";
    #   extraConfig = {
    #     # Sign all commits using ssh key
    #     commit.gpgsign = true;
    #     gpg.format = "ssh";
    #     user.signingkey = "~/.ssh/id_ed25519.pub";
    #   };
    # };

    # Configure neovim
    neovim = {
      enable = true;
      defaultEditor = true;
      vimAlias = true;
      extraPackages = with pkgs; [
        lazygit
        ripgrep
        tree-sitter
      ];
    };
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
