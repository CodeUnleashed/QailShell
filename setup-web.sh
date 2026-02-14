#!/bin/bash
set -euo pipefail

# -------------------------
# Next.js Dev Dependencies (macOS)
# - Homebrew
# - Git
# - Node.js via nvm (recommended)
# - pnpm + yarn
# - Optional: watchman, jq
# -------------------------

# 1) Install Homebrew if missing
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [ -d "/opt/homebrew/bin" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -d "/usr/local/bin" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
else
  echo "Homebrew already installed."
fi

# 2) Update brew (optional but helpful)
brew update || true

# 3) Git
if ! command -v git >/dev/null 2>&1; then
  echo "Installing Git..."
  brew install git
else
  echo "Git already installed."
fi

# 4) Install nvm (Node Version Manager)
if [ ! -d "$HOME/.nvm" ]; then
  echo "Installing nvm..."
  brew install nvm
  mkdir -p "$HOME/.nvm"
else
  echo "nvm already installed."
fi

# Load nvm for this script run
export NVM_DIR="$HOME/.nvm"
if [ -s "$(brew --prefix)/opt/nvm/nvm.sh" ]; then
  # shellcheck disable=SC1090
  . "$(brew --prefix)/opt/nvm/nvm.sh"
else
  echo "ERROR: nvm.sh not found; ensure nvm installed correctly."
  exit 1
fi

# 5) Install latest LTS Node + set default
echo "Installing Node.js (LTS) via nvm..."
nvm install --lts
nvm use --lts
nvm alias default 'lts/*'

# 6) Package managers
echo "Installing package managers..."
brew install pnpm || true
brew install yarn || true

# Ensure corepack is enabled (helps with pnpm/yarn versions when projects pin them)
if command -v corepack >/dev/null 2>&1; then
  corepack enable || true
fi

# 7) Optional utilities commonly handy in JS/Next dev
brew install jq || true
brew install watchman || true


echo ""
echo "✅ Next.js dev dependencies installed."
echo "Node: $(node -v)"
echo "npm:  $(npm -v)"
echo "pnpm: $(pnpm -v 2>/dev/null || echo 'not found')"
echo "yarn: $(yarn -v 2>/dev/null || echo 'not found')"
echo ""
echo "Next steps:"
echo "  mkdir my-app && cd my-app"
echo "  npx create-next-app@latest"
