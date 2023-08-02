#!/bin/bash

# Define the output JSON object
json='{}'

# Loop through all .tf files
for file in $(find . -name "*.tf")
do
  echo $file
  # Extract 'default_tags' block after 'provider "azurerm"' block
  block=$(sed -n '/provider "azurerm"/,/}/p' $file | sed -n '/default_tags/,/}/p')
  echo $block
  # Use awk to get each line with a = and then parse it with sed
  while read -r line
  do
    if [[ $line == *=* ]] && [[ $line != *"tags"* ]]; then
      key=$(echo $line | awk -F'=' '{print $1}' | sed 's/ //g' | sed 's/"//g')
      value=$(echo $line | awk -F'=' '{print $2}' | sed 's/ //g' | sed 's/"//g' | sed 's/,//g')
      json=$(echo $json | jq --arg key "$key" --arg value "$value" '. + {($key): $value}')
    fi
  done <<< "$block"
done

# Export the JSON object as a shell variable
echo $json
# Now you can use the $YOR_SIMPLE_TAGS variable in yor
export YOR_SIMPLE_TAGS=$json
yor tag --tag-groups simple --directory .
