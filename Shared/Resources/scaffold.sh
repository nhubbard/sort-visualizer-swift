#!/usr/bin/env zsh
name=$1
folder="$name.bundle"
echo "Scaffolding $name.bundle..."
# Copy Git ignore file
cp template/.gitignore $folder/.gitignore
# Copy description template
cp template/description.md $folder/description.md
# Copy complexity JSON file
cp template/complexity.json $folder/complexity.json
# Copy and rename implementation templates
for ext in "c" "cpp" "cs" "go" "java" "js" "kt" "py" "rb" "swift"; do
  cp template/template.$ext $folder/$name.$ext
done
# Finished.
echo "Finished scaffolding $name.bundle."