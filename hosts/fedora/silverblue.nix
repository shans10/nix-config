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

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    frequency = "weekly";
    options = "--delete-older-than 3d";
  };

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home = {
    username = "shan";
    homeDirectory = "/var/home/shan";

    # Manage dotfiles
    file = {
      # Nsxiv key-handler executable
      ".config/nsxiv/exec/key-handler" = {
        text = ''
          #!/usr/bin/env bash

          while read file
          do
              case "$1" in
                  # Move file to trash
                  "d")
                      gio trash "$file" && notify-send -a "Nsxiv" -i nsxiv "$file moved to Trash."
                  ;;
                  # Change wallpaper in Gnome
                  "w")
                      gsettings set org.gnome.desktop.background picture-uri-dark $file
                      # notify-send -a "Nsxiv" -i nsxiv "Wallpaper changed." && exit 0
                  ;;
                  esac
          done
        '';
        executable = true;
      };

      # Small script to use nsxiv as wallpaper viewer/changer in Gnome
      ".local/bin/wallpaper" = {
        text = ''
          #!/usr/bin/bash

          # Show all wallpapers from ~/Pictures/Wallpapers in nsxiv
          test -d ~/Pictures/Wallpapers && nsxiv -t ~/Pictures/Wallpapers ||
          # Send error notification if directory doesn't exist
          notify-send -a "Nsxiv" -i nsxiv "ERROR" "Wallpapers directory not found in ~/Pictures."
        '';
        executable = true;
      };
    };

    # Install packages
    packages = with pkgs; [
      # Fonts
      (nerdfonts.override {fonts = ["JetBrainsMono"];})

      # CLI tools
      chezmoi
      eza
      fastfetch
      fzf
      ripgrep
      starship
      nsxiv
      zoxide
    ];

    # Activation scripts to setup additional configurations
    activation = with lib; {
      # Setup dotfiles
      setupDotfiles = lib.hm.dag.entryAfter ["installPackages"] ''
        chezmoi_dir="${config.xdg.dataHome}/chezmoi"
        nvim_dir="${config.xdg.configHome}/nvim"

        # clone and apply dotfiles using chezmoi if they don't exist
        if ! [ -d $chezmoi_dir ]; then
          $DRY_RUN_CMD ${pkgs.chezmoi}/bin/chezmoi init shans10 --branch "fedora-silverblue" --apply
        fi

        # clone neovim config if it doesn't exist
        if ! [ -d $nvim_dir ]; then
          $DRY_RUN_CMD /usr/bin/git clone https://github.com/shans10/astronvim-config.git $nvim_dir
        fi
      '';

      # Some software requires fonts to be present in $XDG_DATA_HOME/fonts in
      # order to use/see them (like Emacs, Flatpak), so just link to them.
      # setupFonts = hm.dag.entryAfter ["writeBoundary"] ''
      #   fontsdir="${config.home.profileDirectory}/share/fonts"
      #   userfontsdir="${config.xdg.dataHome}/fonts"
      #
      #   # create 'userfontsdir' if it doesn't exist
      #   if ! [ -d $userfontsdir ]; then
      #     $DRY_RUN_CMD mkdir $userfontsdir
      #   fi
      #
      #   # remove dead symlinks due to uninstalled font (e.g. all opentype fonts
      #   # are gone, leading to a broken link), etc.
      #   $DRY_RUN_CMD find $userfontsdir -xtype l \
      #     -exec echo unlinking {} \; -exec unlink {} \;
      #
      #   # force necessary because of the many different fonts in colliding
      #   # directories
      #   for dir in $fontsdir/*; do
      #     $DRY_RUN_CMD unlink \
      #       $userfontsdir/$(basename $dir) 2>/dev/null || true
      #     $DRY_RUN_CMD ln -sf $VERBOSE_ARG \
      #       $dir $userfontsdir/$(basename $dir)
      #   done
      # '';
    };
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
        gcc
        lazygit
        tree-sitter
        wl-clipboard
      ];
    };
  };

  # Enable fontconfig
  fonts.fontconfig.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.11"; # Please read the comment before changing.
}
