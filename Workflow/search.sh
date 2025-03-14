#!/bin/zsh --no-rcs

# Set Loading subtitle
if [[ "${arg}" != "${1}" ]]; then
	sub="Search WHOIS for '${1}'"
	subCMD="${sub} in text file"
else
	sub="Loading..."
	subCMD="${sub}"
fi
arg="${1}"

# Set Last Updated Time
readonly whois_file="${alfred_workflow_cache}/${arg//\//%2F}.txt"
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

    [[ ${fileName//\%2F/\/} != ${arg} ]] && echo '{
        "title": "'"${fileName//\%2F/\/}"'",
        "arg": "'"${fileName//\%2F/\/}"'",
        "autocomplete": "'"${fileName//\%2F/\/}"'",
        "variables": { "autocomplete": "1" },
        "icon": { "path": "suggestion.png" }
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
		    "textView": "1",
			"autocomplete": "0"
		},
		"mods": {
			"cmd": {
				"subtitle": "${subCMD}",
				"variables": {
				    "textView": "0",
					"autocomplete": "0"
				}
			}
		}
	},
	$([[ ${useAutocomplete} -eq 1 ]] && autocomplete)
]}
EOB