#!/bin/zsh --no-rcs

if [[ "${forceReload}" -ne 1 ]] && [[ -f "${whois_file}" ]] && [[ "$(date -r "${whois_file}" +%s)" -gt "$(date -v -"59"M +%s)" ]]; then
    # Lookup WHOIS cache file
    readonly whois=$(cat "${whois_file}")
else
    # Lookup WHOIS server
    readonly whois=$(whois "${1}" | tr -d '\r')
    mkdir -p "${alfred_workflow_cache}"
    # Only write to cache if valid entry
    if [[ -z "$(awk '/(^\% This query returned 0 objects\.|^\% Error: Invalid query)/' <<< "${whois}")" ]]; then
        echo "${whois}" > "${whois_file}"
    fi
fi
# Skip formatting if viewing as text file
[[ "${fileView}" -eq 1 ]] && open "${whois_file}" && exit

output="# WHOIS ${1}"

# Domain Information
if [[ $domainInfo -eq 1 ]]; then
	emptyCheck=$(awk 'BEGIN { dateRegex = "[0-9]{4}-[0-9]{2}-[0-9]{2}" }
	/(^[[:blank:]]*Domain Name|^domain)/ && !seen[$0]++ { if ($0 ~ /\./) arr[0] = "* **Domain Name**: " tolower($NF) }
	/^[[:blank:]]*[Rr]egistrar:[^$]/ && !seen[$0]++ { $1=""; arr[1] = "* **Registrar**:" $0 }
	/^[[:blank:]]*Creation Date/ && !seen[$0]++ { start = match($0,dateRegex); arr[2] = "* **Creation Date**: " substr($0,start,10) }
	/Expir.*Date:/ && !seen[$0]++ { start = match($0,dateRegex); arr[3] = "* **Expiry Date**: " substr($0,start,10) }
	/(^[[:blank:]]*Updated Date|^[Ll]ast.?[Uu]pdate)/ && !seen[$0]++ { start = match($0,dateRegex); arr[4] = "* **Renewed Date**: " substr($0,start,10) }
	END {
		for (i = 0; i < length(arr); i++)
			print arr[i]
	}' <<< "${whois}")
	[[ -n "${emptyCheck}" ]] && output+="\n\n### Domain Information\n${emptyCheck}"

	emptyCheck=$(awk '/^[[:blank:]]*Name Server/ && !seen[tolower($NF)]++ { print "* **Name Server**:", tolower($NF) }' <<< "${whois}")
	[[ "${emptyCheck}" != "* **Name Server**: " ]] && output+="\n${emptyCheck}"

	emptyCheck=$(awk '/^[[:blank:]]*Registrar Abuse Contact Email:[^$]/ && !seen[$5]++ { print "* **Registrar Abuse Contact Email**:", tolower($5) }' <<< "${whois}")
	[[ "${emptyCheck}" != "* **Registrar Abuse Contact Email**: "  ]] && output+="\n${emptyCheck}"
fi

# Contact Information
function contactSummary {
    awk -v pattern="${1}" '$0 ~ pattern && !seen[$0]++ { if (toupper($0) !~ /(REDACTED|GDPR.MASK)/ && $0 !~ /(:$|: $)/ && $0 !~ /Email[^@]*$/) print "*", $0 }' <<< "${whois}"
}
if [[ $registrantContact -eq 1 ]]; then
	emptyCheck=$(contactSummary "^Registrant")
	[[ -n "${emptyCheck}" ]] && output+="\n\n### Registrant Contact\n${emptyCheck}"
fi
if [[ $adminContact -eq 1 ]]; then
	emptyCheck=$(contactSummary "^Admin")
	[[ -n "${emptyCheck}" ]] && output+="\n\n### Administrative Contact\n${emptyCheck}"
fi
if [[ $techContact -eq 1 ]]; then
	emptyCheck=$(contactSummary "^Tech")
	[[ -n "${emptyCheck}" ]] && output+="\n\n### Technical Contact\n${emptyCheck}"
fi
if [[ $billingContact -eq 1 ]]; then
	emptyCheck=$(contactSummary "^Billing")
	[[ -n "${emptyCheck}" ]] && output+="\n\n### Billing Contact\n${emptyCheck}"
fi

# Raw WHOIS Data
output+=$(echo "\n\n## Raw WHOIS Data\n
\`\`\`
${whois}
\`\`\`")

# Output Formatted WHOIS Data to Text View
echo "${output}"