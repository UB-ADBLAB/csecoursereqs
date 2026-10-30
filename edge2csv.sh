#!/bin/bash

BASEDIR="$(cd "`dirname "$0"`" && pwd)"
cd "$BASEDIR"

jq -r 'to_entries | map(.value.reqs) | flatten | map(select(has("eid"))) | map(.eid) | map([match("[A-Z]+[0-9]+"; "g")] | map(.string)) | .[] | @csv' data.json > edges.csv
