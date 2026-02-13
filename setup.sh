#!/bin/bash
set -euo pipefail

ZSHRC_FILE="$HOME/.zshrc"
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
NEW_THEME="powerlevel10k/powerlevel10k"

# --- Ensure Homebrew exists (macOS) ---
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is not installed. Install Homebrew first: https://brew.sh/"
  exit 1
fi

# --- Install Git ---
if ! command -v git >/dev/null 2>&1; then
  echo "Git is not installed. Installing..."
  brew install git
fi

# --- Install Oh My Zsh (non-interactive) ---
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "Oh My Zsh already installed."
fi

# Ensure .zshrc exists
if [ ! -f "$ZSHRC_FILE" ]; then
  echo "Creating $ZSHRC_FILE..."
  touch "$ZSHRC_FILE"
fi

# --- Install Powerlevel10k ---
echo "Installing Powerlevel10k..."
mkdir -p "$ZSH_CUSTOM_DIR/themes"
if [ ! -d "$ZSH_CUSTOM_DIR/themes/powerlevel10k" ]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "$ZSH_CUSTOM_DIR/themes/powerlevel10k"
else
  echo "Powerlevel10k already installed."
fi

# Set theme in .zshrc (replace if exists, otherwise append)
if grep -q '^ZSH_THEME=' "$ZSHRC_FILE"; then
  # BSD/macOS sed
  sed -i '' "s|^ZSH_THEME=.*|ZSH_THEME=\"$NEW_THEME\"|" "$ZSHRC_FILE"
else
  echo "ZSH_THEME=\"$NEW_THEME\"" >> "$ZSHRC_FILE"
fi

# --- Install fzf ---
echo "Installing fzf..."
brew install fzf || true

# Enable fzf as Oh My Zsh plugin (add to plugins=(...) safely)
if grep -qE '^[[:space:]]*plugins=\(' "$ZSHRC_FILE"; then
  # plugins line exists; add fzf if missing
  if ! grep -qE '^[[:space:]]*plugins=\([^)]*\bfzf\b' "$ZSHRC_FILE"; then
    sed -i '' 's/^[[:space:]]*plugins=(\([^)]*\))/plugins=(\1 fzf)/' "$ZSHRC_FILE"
    echo "Added fzf to plugins."
  else
    echo "fzf already in plugins."
  fi
else
  # No plugins line: add one
  echo 'plugins=(git fzf)' >> "$ZSHRC_FILE"
  echo "Created plugins=(git fzf)."
fi

# Optional fzf keybindings/completion (no rc modifications)
FZF_INSTALL_SCRIPT="$(brew --prefix)/opt/fzf/install"
if [ -x "$FZF_INSTALL_SCRIPT" ]; then
  "$FZF_INSTALL_SCRIPT" --key-bindings --completion --no-update-rc || true
fi

# --- Install AltTab (macOS) ---
echo "Installing AltTab..."
brew install --cask alt-tab || true

# Launch AltTab
open -a "AltTab" || true

# Add AltTab to Login Items
osascript <<EOF
tell application "System Events"
  if not (exists login item "AltTab") then
    make login item at end with properties {path:"/Applications/AltTab.app", hidden:false}
  end if
end tell
EOF


# --- Install Go ---
if ! command -v go >/dev/null 2>&1; then
  echo "Installing Go..."
  brew install go
else
  echo "Go already installed."
fi

# --- Install Qail ---
echo "Installing Qail..."
mkdir -p "$HOME/qail"
pushd "$HOME/qail"

if [ ! -d "qail" ]; then
  git clone git@github.com:ubaniak/qail.git
fi

cd qail
make build
mkdir -p "$HOME/.qail/bin"
cp -f bin/qail "$HOME/.qail/bin"

# Add Qail PATH exports to .zshrc if not present
if ! grep -q 'export QAILPATH=' "$ZSHRC_FILE"; then
  {
    echo ""
    echo "# Qail"
    echo "export QAILPATH=\"$HOME/.qail/bin\""
    echo "export PATH=\"\$QAILPATH:\$PATH\""
  } >> "$ZSHRC_FILE"
fi
popd

# -------------------------
# Install bat (better cat)
# -------------------------
if ! command -v bat >/dev/null 2>&1; then
  echo "Installing bat..."
  brew install bat
else
  echo "bat already installed."
fi

# macOS installs it as `bat`, but some systems use `batcat`
BAT_PATH=$(command -v bat || command -v batcat || true)

if [ -n "$BAT_PATH" ]; then
  if ! grep -q "alias cat=" "$ZSHRC_FILE"; then
    echo "" >> "$ZSHRC_FILE"
    echo "# Use bat instead of cat" >> "$ZSHRC_FILE"
    echo "alias cat='$BAT_PATH --paging=never'" >> "$ZSHRC_FILE"
  fi
fi

# -------------------------
# Install Maccy (Clipboard Manager)
# -------------------------
if ! brew list --cask maccy >/dev/null 2>&1; then
  echo "Installing Maccy..."
  brew install --cask maccy
else
  echo "Maccy already installed."
fi

# Launch Maccy (will trigger any permission prompts)
open -a "Maccy" || true

# Add Maccy to Login Items
osascript <<'EOF'
tell application "System Events"
  if not (exists login item "Maccy") then
    make login item at end with properties {path:"/Applications/Maccy.app", hidden:false}
  end if
end tell
EOF

echo ""
echo "✅ Done."
echo "Restarting your terminal (running: exec zsh) to load plugins/theme."
exec zsh
