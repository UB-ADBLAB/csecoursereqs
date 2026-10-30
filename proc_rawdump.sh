#!/bin/bash

BASEDIR="$(cd "`dirname "$0"`" && pwd)"
cd "$BASEDIR"

jq '
map(.
+ (.catalognumber | capture("(?<cno>[0-9]+)[ ]*(?<mod>[A-Z]*)")) 
+
{ "reqs": (
.req | split(".") |
    map(split("\\n")) | flatten |
    map(split(";")) | flatten | map(split("and ")) | flatten |
    map(ltrimstr(" ") | ltrimstr(" ") | ltrimstr(" ") |
        rtrimstr(" ") | rtrimstr(" ") | rtrimstr(" ") |
        ltrimstr("\\n") | rtrimstr("\\n")) |
    map(select(test("[^ ]"))) | map ({
        "type": (if . | test("co-r"; "i") then "Co-requisite" else "Pre-requisite" end),
        "rawtext": (. | splits("[, ]or ";"i"))
    }) | map (. +  (
            if .rawtext | test("[A-Z]+[ ]*[0-9]+") then
                .rawtext | capture("(?<sub>[A-Z]{1,3})[ ]{0,1}(?<cno>[0-9]{1,3})")
            else
                {}
            end
    ))
)} 
+ {
    "advisement_required": (.req | test("mandatory advisement session"; "i"))
})
| map((.sub + .cno) as $svid | {
    "key": $svid,
    "value": (
    .  + {
        "vid": $svid,
        "reqs": .reqs | map(
            if has("sub") and has("cno") then
                (.sub + .cno) as $dvid | . + {
                    "vid": $dvid,
                    "eid": ($svid + $dvid)
                }
            else
                .
            end
        )
    }
)})
| group_by(.key) | map({
    "key": .[0].key,
    "value": (. | map(.value)
    | reduce .[] as $o (
        {"eff":"0000-00-00"}; 
        # (1) earlier effective date means it is an older version
        # of a course with the same course number
        if .eff < $o.eff then $o elif .eff > $o.eff then . else
        # (2) otherwise, we just combine all pre-reqs. We do not
        # really care about the mode of instruction for now.
        . + {
            "req": (.req + ". " +  $o.req),
            "reqs": (.reqs + $o.reqs)
        }
        end
    ))
})
| from_entries 
| ((
. | to_entries | map(.value | .reqs | map(.vid) | map(select(.))) | flatten | map({
    "key": .,
    "value": ({"vid": .} + capture("(?<sub>[A-Z]{1,3})(?<cno>[0-9]{1,3})"))
}) | from_entries) + . )
| map_values(
    . + {
        "cno": (.cno | tonumber),
        "reqs": (if has("reqs") then 
                    .reqs | map(
                    if has("cno") then
                        . + {
                            "cno": (.cno | tonumber)
                        }
                    else
                        .
                    end)
                else
                    []
                end
            )
    }
)
' rawdump.json > data.json



