#!/bin/bash

# Fallback uninstall function
fallback_uninstall() {
    # Check if chsh command exists and if .shell.pre-oh-my-zsh file exists
    if hash chsh >/dev/null 2>&1 && [ -f ~/.shell.pre-oh-my-zsh ]; then
        old_shell=$(cat ~/.shell.pre-oh-my-zsh)
        echo "Switching your shell back to '$old_shell':"
        if chsh -s "$old_shell"; then
            rm -f ~/.shell.pre-oh-my-zsh
        else
            echo "Could not change default shell. Change it manually by running chsh"
            echo "or editing the /etc/passwd file."
            exit 1
        fi
    fi

    # Confirm uninstall
    read -r -p "Are you sure you want to remove Oh My Zsh? [y/N] " confirmation
    if [ "$confirmation" != y ] && [ "$confirmation" != Y ]; then
        echo "Uninstall cancelled"
        exit 0
    fi

    # Remove ~/.oh-my-zsh directory
    echo "Removing ~/.oh-my-zsh"
    if [ -d ~/.oh-my-zsh ]; then
        rm -rf ~/.oh-my-zsh
    fi

    # Backup ~/.zshrc file
    if [ -e ~/.zshrc ]; then
        ZSHRC_SAVE=~/.zshrc.omz-uninstalled-$(date +%Y-%m-%d_%H-%M-%S)
        echo "Found ~/.zshrc -- Renaming to ${ZSHRC_SAVE}"
        mv ~/.zshrc "${ZSHRC_SAVE}"
    fi

    # Restore original zsh config
    echo "Looking for original zsh config..."
    ZSHRC_ORIG=~/.zshrc.pre-oh-my-zsh
    if [ -e "$ZSHRC_ORIG" ]; then
        echo "Found $ZSHRC_ORIG -- Restoring to ~/.zshrc"
        mv "$ZSHRC_ORIG" ~/.zshrc
        echo "Your original zsh config was restored."
    else
        echo "No original zsh config found"
    fi

    echo "Thanks for trying out Oh My Zsh. It's been uninstalled."
    echo "Don't forget to restart your terminal!"
}

# Uninstall Oh My Zsh
if [ -d "$HOME/.oh-my-zsh" ]; then
    if command -v uninstall_oh_my_zsh &>/dev/null; then
        uninstall_oh_my_zsh
    elif [ -f "$HOME/.oh-my-zsh/tools/uninstall.sh" ]; then
        sh "$HOME/.oh-my-zsh/tools/uninstall.sh"
    else
        uninstall_script=$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/uninstall.sh)
        if [ -z "$uninstall_script" ]; then
            fallback_uninstall
        else
            echo "$uninstall_script" | sh
        fi
    fi
fi