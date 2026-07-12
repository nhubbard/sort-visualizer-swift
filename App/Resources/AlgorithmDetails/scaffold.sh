#!/usr/bin/env zsh
name=$1
folder="$name"
mkdir "$folder"
echo "Scaffolding $name..."
# Copy description template
cp template/description.md $folder/description.md
# Copy and rename implementation templates
for ext in "c" "cpp" "cs" "go" "java" "js" "kt" "py" "rb" "swift"; do
  cp template/template.$ext $folder/$name.$ext
done
# Finished.
echo "Finished scaffolding $name. Run 'python3 highlight.py' once source files are ready,"
echo "then it writes $name/<lang>.md directly -- no separate shipped folder to sync."
