#!/bin/zsh --no-rcs

# Domain Information
function domainSummary {
	awk 'BEGIN { dateRegex = "[0-9]{4}-[0-9]{2}-[0-9]{2}"; nsArr = 0; abuseArr = 0 }
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
			if (abuseArr > 0) print abuse[i]
	}' <<< "${whois}" | xargs -0 printf "\\n\\n### Domain Information\\n%s"
}

# Contact Information
blacklist=("Domains By Proxy, LLC" \
    "Privacy service provided by Withheld for Privacy ehf" \
    "Private by Design, LLC" \
    "Digital Privacy Corporation" \
    "Super Privacy Service LTD c/o Dynadot" \
    "Identity Protection Service" \
    "Proxy Protection LLC" \
    "Privacy Protect, LLC (PrivacyProtect.org)" \
    "Privacy Hero Inc." \
    "Anonymize LLC")
function contactSummary {
    # Check against privacy services blacklist
    if [[ "${hideBlacklist}" -eq 1 ]]; then
        contactOrg=$(awk -v pattern="${1} Organization" '$0 ~ pattern && !seen[$0]++ { $1=""; $2=""; print substr($0,3) }' <<< "${whois}")
        [[ "${blacklist[@]}" == *"${contactOrg}"* ]] && return
    fi
    # Fetch contact information
    awk -v pattern="^${1}" '$0 ~ pattern && !seen[$0]++ { if (toupper($0) !~ /(REDACTED|GDPR.MASK)/ && $0 !~ /(:$|: $)/ && $0 !~ /Email[^@]*$/) print "*", $0 }' <<< "${whois}" | \
    xargs -0 printf "\\n### ${1} Contact\\n%s"
}

# Fetch WHOIS data
if [[ "${forceReload}" -ne 1 && -f "${whois_file}" ]] && [[ "$(date -r "${whois_file}" +%s)" -gt "$(date -v -"359"M +%s)" ]]; then
    readonly whois=$(< "${whois_file}")
else
    readonly whois=$(whois "${domain}" | tr -d '\r')
    # Only write to cache if valid response
    mkdir -p "${alfred_workflow_cache}"
    grep -q -E "^(\% This query returned 0 objects\.|\% Error: Invalid query|Domain not found|No match for domain)" <<< "${whois}" || echo "${whois}" > "${whois_file}"
fi

# Skip formatting if viewing as text file
[[ "${fileView}" -eq 1 ]] && open "${whois_file}" && exit

# Output formatted whois data to Text View
echo -n "# WHOIS ${domain}"
[[ "${domainInfo}" -eq 1 ]] && domainSummary
[[ "${registrantContact}" -eq 1 ]] && contactSummary "Registrant"
[[ "${adminContact}" -eq 1 ]] && contactSummary "Admin"
[[ "${techContact}" -eq 1 ]] && contactSummary "Tech"
[[ "${billingContact}" -eq 1 ]] && contactSummary "Billing"
echo "\n## Raw WHOIS Data\n\`\`\`\n${whois}\n\`\`\`"