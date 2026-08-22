#!/bin/bash
set -e

mise_installer="$(mktemp)"
curl --fail --silent --show-error --location \
  --retry 5 --retry-all-errors --retry-delay 5 --retry-connrefused \
  https://mise.run -o "$mise_installer"
sh "$mise_installer"
rm -f "$mise_installer"
export PATH="$HOME/.local/bin:$PATH"

mise install # Installs the tools in mise.toml
eval "$(mise activate bash --shims)" # Adds the activated tools to $PATH
pushd ..
tuist install
tuist generate
popd