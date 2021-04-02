{ ... }:

{

  # System - Always show scroll bars.
  system.defaults.NSGlobalDomain.AppleShowScrollBars = "Always";

  # System - Expand save panel by default.
  system.defaults.NSGlobalDomain.NSNavPanelExpandedStateForSaveMode = true;
  system.defaults.NSGlobalDomain.NSNavPanelExpandedStateForSaveMode2 = true;

  # System - Disable 'Are you sure you want to open this application?' dialog.
  system.defaults.LaunchServices.LSQuarantine = false;

  # System - Increase window resize speed for Cocoa applications.
  system.defaults.NSGlobalDomain.NSWindowResizeTime = "0.001";

  # System - Disable auto-correct.
  system.defaults.NSGlobalDomain.NSAutomaticSpellingCorrectionEnabled = false;

  # Keyboard - Enable keyboard access for all controls.
  system.defaults.NSGlobalDomain.AppleKeyboardUIMode = 3;

  # Keyboard - Set a short Delay until key repeat.
  system.defaults.NSGlobalDomain.InitialKeyRepeat = 15;

  # Keyboard - Set a fast keyboard repeat rate.
  system.defaults.NSGlobalDomain.KeyRepeat = 2;

  # Keyboard - Disable press-and-hold for keys in favor of key repeat.
  system.defaults.NSGlobalDomain.ApplePressAndHoldEnabled = false;

  # Trackpad - Enable tap to click for current user and the login screen.
  system.defaults.NSGlobalDomain."com.apple.mouse.tapBehavior" = 1;

  # Dock - Automatically hide and show.
  system.defaults.dock.autohide = true;

  # Dock - Remove the auto-hiding delay.
  system.defaults.dock."autohide-delay" = "0";

  # Dock - Don’t show Dashboard as a Space.
  system.defaults.dock.dashboard-in-overlay = true;

  # Dock - Minimize apps to their icon.
  system.defaults.dock.minimize-to-application = true;

  # Don’t automatically rearrange Spaces based on most recent use.
  system.defaults.dock.mru-spaces = false;

  # Move the dock to the left.
  system.defaults.dock.orientation = "left";

  # Only show open applications in the dock.
  system.defaults.dock.static-only = true;

  # Make the dock tile size tiny.
  system.defaults.dock.tilesize = 2;

  # iCloud - Save to disk by default.
  system.defaults.NSGlobalDomain.NSDocumentSaveNewDocumentsToCloud = false;

  # Finder - Show filename extensions.
  system.defaults.NSGlobalDomain.AppleShowAllExtensions = true;

  # Finder - Disable the warning when changing a file extension.
  system.defaults.finder.FXEnableExtensionChangeWarning = false;

  # Finder - Display full POSIX path as window title.
  system.defaults.finder._FXShowPosixPathInTitle = true;

  # Printer - Expand print panel by default.
  system.defaults.NSGlobalDomain.PMPrintingExpandedStateForPrint = true;
  system.defaults.NSGlobalDomain.PMPrintingExpandedStateForPrint2 = true;

  # The following settings are not configurable via nix-darwin
  system.activationScripts.postActivation.text = ''
    # Keyboard - Automatically illuminate built-in MacBook keyboard in low light.
    defaults write com.apple.BezelServices kDim -bool true

    # Keyboard - Turn off keyboard illumination when computer is not used for 5 minutes.
    defaults write com.apple.BezelServices kDimTime -int 300

    # Trackpad - Use CONTROL (^) with scroll to zoom.
    defaults write com.apple.universalaccess closeViewScrollWheelToggle -bool true
    defaults write com.apple.universalaccess HIDScrollZoomModifierMask -int 262144

    # Follow the keyboard focus while zoomed in.
    defaults write com.apple.universalaccess closeViewZoomFollowsFocus -bool true

    # Bluetooth - Increase sound quality for headphones/headsets.
    defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

    # Set $HOME as the default location for new Finder windows
    defaults write com.apple.finder NewWindowTarget -string "PfDe"
    defaults write com.apple.finder NewWindowTargetPath -string "file://$HOME"

    # Finder - Show the $HOME/Library folder.
    chflags nohidden $HOME/Library

    # Finder - Show hidden files.
    defaults write com.apple.finder AppleShowAllFiles -bool true

    # Finder - Show path bar.
    defaults write com.apple.finder ShowPathbar -bool true

    # Finder - Show status bar.
    defaults write com.apple.finder ShowStatusBar -bool true

    # Finder - Use list view in all Finder windows.
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

    # Finder - Disable the warning before emptying the Trash.
    defaults write com.apple.finder WarnOnEmptyTrash -bool false

    # Finder - Allow text selection in Quick Look.
    defaults write com.apple.finder QLEnableTextSelection -bool true

    # Safari - Enable debug menu.
    defaults write com.apple.Safari IncludeInternalDebugMenu -bool true

    # Safari - Enable the Develop menu and the Web Inspector.
    defaults write com.apple.Safari IncludeDevelopMenu -bool true
    defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
    defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

    # Safari - Add a context menu item for showing the Web Inspector in web views.
    defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

    # Safari - Disable sending search queries to Apple..
    defaults write com.apple.Safari UniversalSearchEnabled -bool false

    # Chrome - Prevent native print dialog, use system dialog instead.
    defaults write com.google.Chrome DisablePrintPreview -boolean true

    # Mail - Copy email addresses as "foo@example.com" instead of "Foo Bar <foo@example.com>".
    defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false

    # Printer - Automatically quit printer app once the print jobs complete.
    defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

    # Game Center - Disable Game Center.
    defaults write com.apple.gamed Disabled -bool true

    # Use AirDrop over every interface.
    defaults write com.apple.NetworkBrowser BrowseAllInterfaces 1

    # Mac App Store - Enable the automatic update check
    defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true

    # Mac App Store - Check for software updates daily, not just once per week
    defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

    # Mac App Store - Download newly available updates in background
    defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1

    # Mac App Store - Install System data files & security updates
    defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1

  '';
}
