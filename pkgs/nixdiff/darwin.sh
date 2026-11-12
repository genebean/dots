cd ~/repos/dots

echo "=== Homebrew package updates ==="
brew outdated || true

echo ""
echo "=== Homebrew cask updates ==="
brew outdated --cask || true

echo ""
echo "=== Mac App Store updates ==="
mas outdated || true

echo ""
echo "Building Darwin system..."
# sudo strips NIX_CONFIG, so the flag has to be explicit
sudo darwin-rebuild build --flake . --option accept-flake-config true

echo ""
echo "=== Package changes ==="
nvd diff /run/current-system result
