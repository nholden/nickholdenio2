#!/bin/bash

rss=$(curl -s https://www.campsite.co/changelog/rss)
urls=( $(xmllint --xpath "//item/link/text()" - <<<"$rss") )
result_json="[]"

for url in ${urls[@]}; do
  page=$(curl -s $url)
  if (grep -q nick.jpeg <<<"$page")
  then
    page_title=$(xmllint --xpath "//title/text()" - <<<"$page" | sed 's/ · Campsite//g')
    result_json=$(jq --arg title "$page_title" --arg url "$url" '.[. | length] |= . + {"title": $title,"url": $url}' <<<"$result_json")
  fi
done

echo $result_json
