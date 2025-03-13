# Set Loading subtitle
[[ "${arg}" != "${1}" ]] && unset textView
arg="${1}"

if [[ -z "${textView}" ]]; then
	sub="Search WHOIS for '${1}'"
else
	sub="Loading..."
fi

# JSON Output
cat << EOB
{
"variables": {
	"arg": "$arg"
},
"items": [
	{
		"title": "${alfred_workflow_name}",
		"subtitle": "${sub}",
		"arg": "${1}",
		"variables": {"textView": "1"},
		"mods": {
			"cmd": {
				"subtitle": "View WHOIS for '${1}' as text file",
				"variables": {"textView": "0"}
			}
		}
	}
]}
EOB