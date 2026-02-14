#!/bin/bash
set -euo pipefail

ZSHRC_FILE="$HOME/.zshrc"
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
NEW_THEME="powerlevel10k/powerlevel10k"

# -------------------------
# Install Homebrew if missing
# -------------------------
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found. Installing..."

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add Homebrew to PATH for Apple Silicon Macs
  if [ -d "/opt/homebrew/bin" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  # Add Homebrew to PATH for Intel Macs
  if [ -d "/usr/local/bin" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  echo "Homebrew installed successfully."
else
  echo "Homebrew already installed."
fi

# --- Install Git ---
if ! command -v git >/dev/null 2>&1; then
  echo "Git is not installed. Installing..."
  brew install git
fi

# -------------------------
# Install modern Vim + configure colors
# -------------------------

echo "Setting up Vim..."

# Install Homebrew Vim (better than macOS system vim)
if ! brew list vim >/dev/null 2>&1; then
  brew install vim
else
  echo "Homebrew vim already installed."
fi

# Ensure Homebrew Vim is first in PATH
if [[ "$(uname -m)" == "arm64" ]]; then
  VIM_PREFIX="/opt/homebrew/bin"
else
  VIM_PREFIX="/usr/local/bin"
fi

if ! grep -q "$VIM_PREFIX" "$ZSHRC_FILE"; then
  echo "" >> "$ZSHRC_FILE"
  echo "# Ensure Homebrew Vim is first in PATH" >> "$ZSHRC_FILE"
  echo "export PATH=\"$VIM_PREFIX:\$PATH\"" >> "$ZSHRC_FILE"
fi

# Create a modern ~/.vimrc if it doesn't exist
VIMRC_FILE="$HOME/.vimrc"

if [ ! -f "$VIMRC_FILE" ]; then
  cat <<EOF > "$VIMRC_FILE"
syntax on
set number
set relativenumber
set tabstop=2
set shiftwidth=2
set expandtab
set smartindent
set termguicolors
set background=dark
EOF
  echo "Created ~/.vimrc with syntax highlighting."
else
  # Ensure syntax highlighting exists
  if ! grep -q "syntax on" "$VIMRC_FILE"; then
    echo "syntax on" >> "$VIMRC_FILE"
  fi
  if ! grep -q "set termguicolors" "$VIMRC_FILE"; then
    echo "set termguicolors" >> "$VIMRC_FILE"
  fi
fi

# Ensure 256-color terminal support
if ! grep -q 'export TERM=' "$ZSHRC_FILE"; then
  echo "" >> "$ZSHRC_FILE"
  echo "# Enable 256 color support" >> "$ZSHRC_FILE"
  echo "export TERM=xterm-256color" >> "$ZSHRC_FILE"
fi

# Set Vim as Git default editor
if command -v git >/dev/null 2>&1; then
  CURRENT_EDITOR=$(git config --global core.editor || echo "")

  if [ "$CURRENT_EDITOR" != "vim" ]; then
    echo "Setting vim as Git default editor..."
    git config --global core.editor "vim"
  else
    echo "Git editor already set to vim."
  fi
fi

echo "Vim configured successfully."

# -------------------------
# Install Nerd Font (MesloLGS NF) for Powerlevel10k
# https://github.com/ryanoasis/nerd-fonts
# -------------------------
echo "Installing Nerd Font (MesloLGS NF)..."
brew install --cask font-meslo-lg-nerd-font || true

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

# -------------------------
# Suppress Powerlevel10k instant prompt warning (fast + no warning)
# -------------------------
P10K_QUIET_LINE='typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet'
if ! grep -Fq "$P10K_QUIET_LINE" "$ZSHRC_FILE"; then
  tmpfile="$(mktemp)"
  {
    echo "$P10K_QUIET_LINE"
    echo ""
    cat "$ZSHRC_FILE"
  } > "$tmpfile"
  mv "$tmpfile" "$ZSHRC_FILE"
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
  sed -i '' "s|^ZSH_THEME=.*|ZSH_THEME=\"$NEW_THEME\"|" "$ZSHRC_FILE"
else
  echo "ZSH_THEME=\"$NEW_THEME\"" >> "$ZSHRC_FILE"
fi

# --- Install fzf ---
echo "Installing fzf..."
brew install fzf || true

# Enable fzf as Oh My Zsh plugin (add to plugins=(...) safely)
if grep -qE '^[[:space:]]*plugins=\(' "$ZSHRC_FILE"; then
  if ! grep -qE '^[[:space:]]*plugins=\([^)]*\bfzf\b' "$ZSHRC_FILE"; then
    sed -i '' 's/^[[:space:]]*plugins=(\([^)]*\))/plugins=(\1 fzf)/' "$ZSHRC_FILE"
    echo "Added fzf to plugins."
  else
    echo "fzf already in plugins."
  fi
else
  echo 'plugins=(git fzf)' >> "$ZSHRC_FILE"
  echo "Created plugins=(git fzf)."
fi

# -------------------------
# Install AltTab (only if not installed)
# -------------------------
if [ ! -d "/Applications/AltTab.app" ]; then
  echo "AltTab not found. Installing..."
  brew install --cask alt-tab
  open -a "AltTab" || true
  osascript <<EOF
tell application "System Events"
  if not (exists login item "AltTab") then
    make login item at end with properties {path:"/Applications/AltTab.app", hidden:false}
  end if
end tell
EOF
else
  echo "AltTab already installed. Skipping."
fi

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
pushd "$HOME/qail" >/dev/null

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
popd >/dev/null

# -------------------------
# Install bat (better cat)
# -------------------------
if ! command -v bat >/dev/null 2>&1; then
  echo "Installing bat..."
  brew install bat
else
  echo "bat already installed."
fi

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
if [ ! -d "/Applications/Maccy.app" ]; then
  echo "Installing Maccy..."
  brew install --cask maccy
  open -a "Maccy" || true

  osascript <<'EOF'
tell application "System Events"
  if not (exists login item "Maccy") then
    make login item at end with properties {path:"/Applications/Maccy.app", hidden:false}
  end if
end tell
EOF
else
  echo "Maccy already installed."
fi

# -------------------------
# Zsh plugins:
# 1) zsh-autocomplete
# 2) zsh-autosuggestions
# 3) fast-syntax-highlighting
# -------------------------
mkdir -p "$ZSH_CUSTOM_DIR/plugins"

# 1) zsh-autocomplete (clone into OMZ custom plugins)
if [ ! -d "$ZSH_CUSTOM_DIR/plugins/zsh-autocomplete" ]; then
  echo "Installing zsh-autocomplete..."
  git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git \
    "$ZSH_CUSTOM_DIR/plugins/zsh-autocomplete"
else
  echo "zsh-autocomplete already installed."
fi

# Ensure zsh-autocomplete is sourced BEFORE Oh My Zsh is sourced.
AUTOCOMPLETE_LINE='source ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh'
if ! grep -Fq "$AUTOCOMPLETE_LINE" "$ZSHRC_FILE"; then
  if grep -qE '^[[:space:]]*source[[:space:]].*oh-my-zsh\.sh' "$ZSHRC_FILE"; then
    sed -i '' "/^[[:space:]]*source[[:space:]].*oh-my-zsh\.sh/i\\
$AUTOCOMPLETE_LINE
" "$ZSHRC_FILE"
  else
    tmpfile="$(mktemp)"
    {
      echo "$AUTOCOMPLETE_LINE"
      echo ""
      cat "$ZSHRC_FILE"
    } > "$tmpfile"
    mv "$tmpfile" "$ZSHRC_FILE"
  fi
  echo "Configured zsh-autocomplete to load before Oh My Zsh."
else
  echo "zsh-autocomplete source line already present."
fi

# 2) zsh-autosuggestions
if [ ! -d "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions" ]; then
  echo "Installing zsh-autosuggestions..."
  git clone https://github.com/zsh-users/zsh-autosuggestions \
    "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions"
else
  echo "zsh-autosuggestions already installed."
fi

# 3) fast-syntax-highlighting
if [ ! -d "$ZSH_CUSTOM_DIR/plugins/fast-syntax-highlighting" ]; then
  echo "Installing fast-syntax-highlighting..."
  git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git \
    "$ZSH_CUSTOM_DIR/plugins/fast-syntax-highlighting"
else
  echo "fast-syntax-highlighting already installed."
fi

# -------------------------
# Remove old zsh-syntax-highlighting if present (conflicts)
# -------------------------
sed -i '' '/zsh-syntax-highlighting/d' "$ZSHRC_FILE"
rm -rf "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting" 2>/dev/null || true

# -------------------------
# Ensure plugin list is sane + ordered
# autosuggestions before highlighting
# -------------------------
if grep -qE '^[[:space:]]*plugins=\(' "$ZSHRC_FILE"; then
  sed -i '' 's/^[[:space:]]*plugins=(.*$/plugins=(git fzf zsh-autosuggestions fast-syntax-highlighting)/' "$ZSHRC_FILE"
else
  echo 'plugins=(git fzf zsh-autosuggestions fast-syntax-highlighting)' >> "$ZSHRC_FILE"
fi

echo ""
echo "✅ Done."
echo "Restart your terminal or run: exec zsh"
