#!/bin/bash

# List of YAML files
files=("file1.yaml" "file2.yaml" "file3.yaml" "file4.yaml" "file5.yaml")

# Normalize and store as JSON
for file in "${files[@]}"; do
  yq -o=json e '... | sort_keys(.)' "$file" > "${file%.yaml}.json"
done

# Compare files pairwise
for ((i = 0; i < ${#files[@]} - 1; i++)); do
  for ((j = i + 1; j < ${#files[@]}; j++)); do
    echo "Diff between ${files[i]} and ${files[j]}:"
    diff "${files[i]%.yaml}.json" "${files[j]%.yaml}.json"
  done
done

# Count the syscalls
yq '.spec.containers[].syscalls | length' file1.yaml
yq '.spec.containers[].syscalls | length' file2.yaml
yq '.spec.containers[].syscalls | length' file3.yaml
yq '.spec.containers[].syscalls | length' file4.yaml
yq '.spec.containers[].syscalls | length' file5.yaml