#!/bin/bash
set -e
curl https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"

mise install # Installs the tools in mise.toml
eval "$(mise activate bash --shims)" # Adds the activated tools to $PATH
pushd ..
tuist install
tuist generate
popd