json='{}'

for file in $(find . -name "*.tf"); do
  start=$(grep -n 'locals {' $file | cut -d : -f 1)
  if [[ -z $start ]]; then continue; fi
  end=$(awk -v start=$start '/locals {/ {p=1} p {c+=gsub("{","{"); c-=gsub("}","}"); if (c == 0) {print NR; exit}}' $file)
  block=$(sed -n "${start},${end}p" $file | sed -n '/tags {/,/}/p')

  while read -r line; do
    key=$(echo $line | awk -F'=' '{gsub(/^[ \t"]+|[ \t",]+$/, "", $1); print $1}')
    value=$(echo $line | awk -F'=' '{gsub(/^[ \t"]+|[ \t",]+$/, "", $2); print $2}')
    if [[ -n $key && -n $value ]]; then
      json=$(echo $json | jq --arg key "$key" --arg value "$value" '. + {($key): $value}')
    fi
  done <<< "$block"
done

echo $json
export YOR_SIMPLE_TAGS=$json
yor tag --tag-groups simple --directory .
fi
