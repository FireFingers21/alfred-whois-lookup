#!/bin/zsh --no-rcs

if [[ "${forceReload}" -ne 1 ]] && [[ -f "${whois_file}" ]] && [[ "$(date -r "${whois_file}" +%s)" -gt "$(date -v -"359"M +%s)" ]]; then
    # Lookup WHOIS cache file
    readonly whois=$(cat "${whois_file}")
else
    # Lookup WHOIS server
    [[ "${forceReload}" -eq 1 ]] && 1=$(echo "${1:6}" | head -n 1)
    readonly whois=$(whois "${1}" | tr -d '\r')
    mkdir -p "${alfred_workflow_cache}"
    # Only write to cache if valid entry
    if [[ -z "$(awk '/(^\% This query returned 0 objects\.|^\% Error: Invalid query|^Domain not found|^No match for domain)/' <<< "${whois}")" ]]; then
        echo "${whois}" > "${whois_file}"
    fi
fi
# Skip formatting if viewing as text file
[[ "${fileView}" -eq 1 ]] && open "${whois_file}" && exit

output="# WHOIS ${1}"

# Domain Information
if [[ $domainInfo -eq 1 ]]; then
	emptyCheck=$(awk 'BEGIN { dateRegex = "[0-9]{4}-[0-9]{2}-[0-9]{2}"; nsArr = 0; abuseArr = 0 }
	/(^[[:blank:]]*Domain [Nn]ame|^domain)/ && !seen[$0]++ { if ($0 ~ /\./) arr[0] = "* **Domain Name**: " tolower($NF) }
	/^[[:blank:]]*[Rr]egistrar:[^$]/ && !seen[$0]++ { $1=""; arr[1] = "* **Registrar**:" $0 }
	/^[[:blank:]]*Creation Date/ && !seen[$0]++ { start = match($0,dateRegex); arr[2] = "* **Creation Date**: " substr($0,start,10) }
	/Expir.*Date:/ && !seen[$0]++ { start = match($0,dateRegex); arr[3] = "* **Expiry Date**: " substr($0,start,10) }
	/(^[[:blank:]]*Updated Date|^[Ll]ast.?([Uu]pdate|Modified))/ && !seen[$0]++ { start = match($0,dateRegex); arr[4] = "* **Renewed Date**: " substr($0,start,10) }
	/^[[:blank:]]*Name Server/ && $0 !~ /(:$|: $)/ && !seen[tolower($NF)]++ { ns[nsArr++] = "* **Name Server**: " tolower($NF) }
	/^[[:blank:]]*Registrar Abuse Contact Email:[^$]/ && !seen[$5]++ { abuse[abuseArr++] = "* **Registrar Abuse Contact Email**: " tolower($5) }
	END {
		for (i = 0; i < length(arr); i++)
			print arr[i]
		for (i = 0; i < length(ns); i++)
			print ns[i]
		for (i = 0; i < length(abuseArr); i++)
			print abuse[i]
	}' <<< "${whois}")
	[[ -n "${emptyCheck}" ]] && output+="\n\n### Domain Information\n${emptyCheck}"
fi

# Contact Information
blacklist=("Domains By Proxy, LLC" \
"Privacy service provided by Withheld for Privacy ehf" \
"Private by Design, LLC" \
"Digital Privacy Corporation" \
"Super Privacy Service LTD c/o Dynadot" \
"Identity Protection Service")
function contactSummary {
    # Check against privacy services blacklist
    if [[ "${hideBlacklist}" -eq 1 ]]; then
        contactOrg=$(awk -v pattern="${1} Organization" '$0 ~ pattern && $0 !~ /(:$|: $|REDACTED)/ && !seen[$0]++ { $1=""; $2=""; print substr($0,3) }' <<< "${whois}")
        [[ -n "${contactOrg}" && ("${blacklist[@]}" == *"${contactOrg}"* || "${contactOrg}" == "Contact Privacy Inc. Customer"*) ]] && exit
    fi
    # Fetch contact information
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