#!/usr/bin/env zsh
name=$1
folder="$name.bundle"
mkdir "$folder"
echo "Scaffolding $name.bundle..."
# Copy Git ignore file
cp template.bundle/.gitignore $folder/.gitignore
# Copy description template
cp template.bundle/description.md $folder/description.md
# Copy complexity JSON file
cp template.bundle/complexity.json $folder/complexity.json
# Copy and rename implementation templates
for ext in "c" "cpp" "cs" "go" "java" "js" "kt" "py" "rb" "swift"; do
  cp template.bundle/template.$ext $folder/$name.$ext
done
# Finished.
echo "Finished scaffolding $name.bundle."
