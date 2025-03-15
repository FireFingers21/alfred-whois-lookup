#!/bin/zsh --no-rcs

# Set Loading subtitle
if [[ "${loading}" -eq 1 && "${autocomplete}" -ne 1 ]]; then
	sub="Loading..."
	subCMD="${sub}"
else
	sub="Search WHOIS for '${1}'"
	subCMD="${sub} in text file"
fi
arg="${1}"

# Set Last Updated Time
whois_file="${alfred_workflow_cache}/${arg//\//%2F}.txt"
[[ -f "${whois_file}" ]] && lastUpdatedMinutes=$((($(date +%s)-$(date -r "${whois_file}" +%s))/60))

if [[ ${lastUpdatedMinutes} -eq 0 || ${lastUpdatedMinutes} -gt 59 ]]; then
    lastUpdated="Just now"
elif [[ ${lastUpdatedMinutes} -eq 1 ]]; then
    lastUpdated="${lastUpdatedMinutes} minute ago"
else
    lastUpdated="${lastUpdatedMinutes} minutes ago"
fi

# Autocomplete
function autocomplete {
    while IFS= read -r file; do
    fileName=$(basename -s ".txt" "${file}")
    whois_file="${file}"
    [[ -f "${whois_file}" ]] && lastUpdatedMinutes=$((($(date +%s)-$(date -r "${whois_file}" +%s))/60))

    if [[ ${lastUpdatedMinutes} -eq 0 || ${lastUpdatedMinutes} -gt 59 ]]; then
        lastUpdated="Just now"
    elif [[ ${lastUpdatedMinutes} -eq 1 ]]; then
        lastUpdated="${lastUpdatedMinutes} minute ago"
    else
        lastUpdated="${lastUpdatedMinutes} minutes ago"
    fi

    [[ ${fileName//\%2F/\/} != ${arg} ]] && echo '{
        "title": "'"${fileName//\%2F/\/}"'",
        "arg": "'"${fileName//\%2F/\/}"'",
        "autocomplete": "'"${fileName//\%2F/\/}"'",
        "icon": { "path": "suggestion.png" },
        "variables": {
            "arg": "'"${fileName//\%2F/\/}"'",
            "loading": "1",
            "lastUpdated": "'"${lastUpdated}"'",
            "whois_file": "'"${whois_file}"'",
            '"$([[ ${quickAutocomplete} -eq 1 ]] && echo '"textView": "1"' || echo '"autocomplete": "1"')"'
        }
    },'
    done <<< "${domainList}"
}
if [[ ${useAutocomplete} -eq 1 ]]; then
    domainList=$(find ${alfred_workflow_cache} -maxdepth 1 -iname "${arg}*.txt" | head -n 8)
    topDomain=$(basename -s ".txt" "$(echo ${domainList} | head -n 1)")
    autocompleteJSON="${topDomain//\%2F/\/}"
else
    autocompleteJSON="${arg}"
fi

# JSON Output
cat << EOB
{
"variables": {
	"arg": "${arg}",
	"lastUpdated": "${lastUpdated}",
	"whois_file": "${whois_file}"
},
"items": [
	{
		"title": "${alfred_workflow_name}",
		"subtitle": "${sub}",
		"arg": "${arg}",
		"autocomplete": "${autocompleteJSON}",
		"variables": {
		    "loading": "1",
		    "textView": "1",
			"autocomplete": "0"
		},
		"mods": {
			"cmd": {
				"subtitle": "${subCMD}",
				"variables": {
				    "loading": "1",
				    "textView": "0",
					"autocomplete": "0"
				}
			}
		}
	},
	$([[ ${useAutocomplete} -eq 1 && ${loading} -ne 1 ]] && autocomplete)
]}
EOB