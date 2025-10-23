#!/bin/zsh --no-rcs

# Loading Screen
[[ "${loading}" -eq 1 ]] && echo '{"items":[{"title":"'"${alfred_workflow_name}"'","subtitle":"Loading...","valid":"0","mods":{"alt":{"subtitle":"Loading..."}}}]}' && exit

# Get Last Updated Time
function getLastUpdated {
    if [[ ${1} -eq 0 || ${1} -gt 359 ]]; then
        lastUpdated="Just now"
    elif [[ ${1} -eq 1 ]]; then
        lastUpdated="${1} minute ago"
    elif [[ ${1} -gt 1 && ${1} -lt 60 ]]; then
        lastUpdated="${1} minutes ago"
    elif [[ ${1} -ge 60 && ${1} -lt 120 ]]; then
        lastUpdated="$((${1}/60)) hour ago"
    else
        lastUpdated="$((${1}/60)) hours ago"
    fi
}
whois_file="${alfred_workflow_cache}/${1//\//%2F}.txt"
[[ -f "${whois_file}" ]] && getLastUpdated "$((($(date +%s)-$(date -r "${whois_file}" +%s))/60))" || lastUpdated="Just now"

# Autocomplete
if [[ ${useAutocomplete} -eq 1 ]]; then
    # Search by name or TLD
    domainList=$(find ${alfred_workflow_cache} -maxdepth 1 -iname "${1//#.*/*${1}}*.txt" -not -iname "${1}.txt" | head -n 8)
    topAutocomplete=$(basename -s ".txt" "${domainList%%$'\n'*}")
    # Generate results
    searchSuggestions="$(while IFS= read -r file; do
        fileName=$(basename -s ".txt" "${file}")
        fileName="${fileName//\%2F/\/}"
        getLastUpdated "$((($(date +%s)-$(date -r "${file}" +%s))/60))"
        # hex code: #4CA9F6
        cat << EOB
        {
            "title": "${fileName}",
            "arg": "${fileName}",
            "autocomplete": "${fileName}",
            "valid": "${quickAutocomplete}",
            "icon": { "path": "suggestion.png" },
            "mods": { "cmd": { "valid": false } },
            "variables": { "loading":"1", "lastUpdated":"${lastUpdated}", "whois_file":"${file}" }
        },
EOB
    done <<< "${domainList}")"
fi

# JSON Output
cat << EOB
{
"variables": {
	"lastUpdated": "${lastUpdated}",
	"whois_file": "${whois_file}"
},
"items": [
	{
		"title": "${alfred_workflow_name}",
		"subtitle": "Search WHOIS for ${1}",
		"arg": "${1}",
		"autocomplete": "${${topAutocomplete:+${topAutocomplete//\%2F/\/}}:-${1}}",
		"variables": { "loading": "1" },
		"mods": {
			"cmd": {
				"subtitle": "Search WHOIS for ${1} in text file",
				"variables": { "loading": "1", "fileView": "1" }
			}
		}
	},
	${searchSuggestions}
]}
EOB