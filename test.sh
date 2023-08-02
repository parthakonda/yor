#!/bin/bash

json='{}'

for file in $(find . -name "*.tf")
do
  # Get the line numbers for the start and end of the locals block
  start=$(grep -n 'locals {' $file | cut -d : -f 1)
  end=$(grep -n '}' $file | cut -d : -f 1 | awk -v start=$start '$1 > start {print $1; exit}')

  # If 'locals {' is not found in the file, skip to next file
  if [[ -z $start ]]; then
    # echo "No 'locals {' found in $file, skipping..."
    continue
  fi

  # Extract the default_tags block within the locals block
  block=$(sed -n "${start},${end}p" $file | sed -n '/default_tags {/,/}/p')

  while read -r line
  do
    if [[ $line == *=* ]] && [[ $line != *"default_tags"* ]]; then
      key=$(echo $line | awk -F'=' '{print $1}' | sed 's/ //g' | sed 's/"//g')
      value=$(echo $line | awk -F'=' '{print $2}' | sed 's/ //g' | sed 's/"//g' | sed 's/,//g')
      json=$(echo $json | jq --arg key "$key" --arg value "$value" '. + {($key): $value}')
    fi
  done <<< "$block"
done



# Print the JSON object as a shell variable to a file
echo $json
export YOR_SIMPLE_TAGS=$json
# Now you can source this file in GitLab CI/CD pipeline script
# source yor_tags.sh
yor tag --tag-groups simple --directory .
