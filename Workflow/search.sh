#!/bin/zsh --no-rcs

# Set Loading subtitle
if [[ "${loading}" -eq 1 && "${autocomplete}" -ne 1 ]]; then
	sub="Loading..."
	subCMD="${sub}"
else
	sub="Search WHOIS for '${1}'"
	subCMD="${sub} in text file"
fi

# Get Last Updated Time
function getLastUpdated {
    if [[ ${1} -eq 0 || ${1} -gt 59 ]]; then
        lastUpdated="Just now"
    elif [[ ${1} -eq 1 ]]; then
        lastUpdated="${1} minute ago"
    else
        lastUpdated="${1} minutes ago"
    fi
}
whois_file="${alfred_workflow_cache}/${1//\//%2F}.txt"
[[ -f "${whois_file}" ]] && getLastUpdated "$((($(date +%s)-$(date -r "${whois_file}" +%s))/60))" || lastUpdated="Just now"

# Autocomplete
arg="${1}"
function autocomplete {
    while IFS= read -r file; do
        fileName=$(basename -s ".txt" "${file}")
        fileName="${fileName//\%2F/\/}"
        getLastUpdated "$((($(date +%s)-$(date -r "${file}" +%s))/60))"

        [[ "${fileName}" != "${arg}" ]] && echo '{
            "title": "'"${fileName}"'",
            "arg": "'"${fileName}"'",
            "autocomplete": "'"${fileName}"'",
            "icon": { "path": "suggestion.png" },
            "mods": { "cmd": { "variables": { "autocomplete": "1" } } },
            "variables": {
                "loading": "1",
                "lastUpdated": "'"${lastUpdated}"'",
                "whois_file": "'"${file}"'",
                '"$([[ ${quickAutocomplete} -ne 1 ]] && echo '"autocomplete": "1"')"'
            }
        },'
    done <<< "${domainList}"
}
if [[ ${useAutocomplete} -eq 1 ]]; then
    domainList=$(find ${alfred_workflow_cache} -maxdepth 1 -iname "${1}*.txt" | head -n 8)
    topDomain=$(basename -s ".txt" "$(echo ${domainList} | head -n 1)")
    autocompleteJSON="${topDomain//\%2F/\/}"
else
    autocompleteJSON="${1}"
fi

# JSON Output
cat << EOB
{
"variables": {
	"autocomplete": "0",
	"lastUpdated": "${lastUpdated}",
	"whois_file": "${whois_file}"
},
"items": [
	{
		"title": "${alfred_workflow_name}",
		"subtitle": "${sub}",
		"arg": "${1}",
		"autocomplete": "${autocompleteJSON}",
		"variables": { "loading": "1" },
		"mods": {
			"cmd": {
				"subtitle": "${subCMD}",
				"variables": {
				    "loading": "1",
				    "fileView": "1"
				}
			}
		}
	},
	$([[ ${useAutocomplete} -eq 1 && ${loading} -ne 1 ]] && autocomplete)
]}
EOB