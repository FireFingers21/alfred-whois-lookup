#!/bin/zsh --no-rcs

# Privacy Services Blacklist
readonly -a blacklist=(
    "Domains By Proxy, LLC"
    "Privacy service provided by Withheld for Privacy ehf"
    "Private by Design, LLC"
    "Digital Privacy Corporation"
    "Super Privacy Service LTD c/o Dynadot"
    "Identity Protection Service"
    "Proxy Protection LLC"
    "Privacy Protect, LLC (PrivacyProtect.org)"
    "Privacy Hero Inc."
    "Anonymize LLC"
    "Whois Privacy Protection Service, Inc."
    "Knock Knock WHOIS Not There, LLC"
    "Contact Privacy Inc. Customer *"
)

# Domain Information
function domainSummary {
	awk 'BEGIN {
	    dateRegex = "[0-9]{4}-[0-9]{2}-[0-9]{2}"
		nsArr = 0; abuseArr = 0
	}
	/(^[[:blank:]]*[Dd]omain [Nn]ame|^Domain:)/ && !seen[$0]++ {
	    if ($0 ~ /\./) arr[0] = "* **Domain Name**: " tolower($NF)
	}
	/^[[:blank:]]*[Rr]egistrar:[^$]/ && !seen[$0]++ {
	    $1=""; arr[1] = "* **Registrar**:" $0
	}
	/^[[:blank:]]*Creation Date|Created/ && !seen[$0]++ {
	    start = match($0,dateRegex)
		if ($0 ~ /[0-9]{4}-[0-9]{2}-[0-9]{2}/) arr[2] = "* **Creation Date**: " substr($0,start,10)
	}
	/Expir.*Date:/ && !seen[$0]++ {
	    start = match($0,dateRegex)
		if ($0 ~ /[0-9]{4}-[0-9]{2}-[0-9]{2}/) arr[3] = "* **Expiry Date**: " substr($0,start,10)
	}
	/(^[[:blank:]]*Updated Date|^[Ll]ast.?([Uu]pdate|Modified))/ && !seen[$0]++ {
	    start = match($0,dateRegex)
		if ($0 ~ /[0-9]{4}-[0-9]{2}-[0-9]{2}/) arr[4] = "* **Renewed Date**: " substr($0,start,10)
	}
	/^[[:blank:]]*Name Server|Nserver/ && $0 !~ /:[[:space:]]*$/ && !seen[tolower($NF)]++ {
	    ns[nsArr++] = "* **Name Server**: " tolower($NF)
	}
	/^[[:blank:]]*Registrar Abuse Contact Email/ && $0 !~ /:[[:space:]]*$/ && !seen[$5]++ {
	    abuse[abuseArr++] = "* **Registrar Abuse Contact Email**: " tolower($5)
	}
	END {
		for (i = 0; i <= 4; i++) print arr[i]
		for (i = 0; i < nsArr; i++) print ns[i]
		for (i = 0; i < abuseArr; i++) print abuse[i]
	}' <<< "${whois}" | grep -vx '' | xargs -0 printf "\\n\\n### Domain Information\\n%s"
}

# Contact Information
function contactSummary {
    # Check against privacy services blacklist
    if [[ "${hideBlacklist}" -eq 1 ]]; then
        # Check each field separately within array, return nothing if there's a match
        contactOrg=("${(f)$(awk -v pattern="${type} Organization" '$0 ~ pattern && !seen[$0]++ { $1=""; $2=""; print substr($0,3) }' <<< "${whois}")}")
        for entry in "${blacklist[@]}"; do
            (( ${contactOrg[(I)${entry}]} )) && return
        done
    fi
    # Fetch contact information, reject if redacted
    awk -v pattern="^${1}" '$0 ~ pattern && !seen[$0]++ {
        if (toupper($0) !~ /(REDACTED|GDPR.MASK)/ && $0 !~ /:[[:space:]]*$/ && $0 !~ /Email[^@]*$/ && NF > 2) {
            sub(/(Registrant|Admin|Tech|Billing).*:/, "**&**")
            sub(/[[:space:]]*:\*\*/, "**:")
            print "*", $0
        }
    }' <<< "${whois}" | xargs -0 printf "\\n### ${1} Contact\\n%s"
}

# Fetch WHOIS data
if [[ "${forceReload}" -ne 1 && -f "${whois_file}" ]] && [[ "$(date -r "${whois_file}" +%s)" -gt "$(date -v -"359"M +%s)" ]]; then
    # Read from cache
    whois=$(< "${whois_file}")
else
    # Only write to cache if valid response
    whoisData=$(whois "${domainEncoded}")
    if [[ "${?}" -eq 0 ]]; then
        whois="${whoisData//$'\r'/}"
        mkdir -p "${alfred_workflow_cache}"
        if ! grep -q -E "(^[[:blank:]]*[Dd]omain [Nn]ame|^Domain:)" <<< "${whois}" \
        && grep -q -E "^(% This query returned 0 objects\.|% Error: Invalid query|Domain.*not found|Not found|%% NOT FOUND|No match for domain)" <<< "${whois}"
        then
            :
        else
            echo "${whois}" > "${whois_file}"
        fi
    else
        printf "# WHOIS ${domain}\n\n---\n\n*Unable to connect to WHOIS server*" && exit
    fi
fi

# Skip formatting if viewing as text file
[[ "${fileView}" -eq 1 ]] && open "${whois_file}" && exit

# Output formatted whois data to Text View
printf "# WHOIS ${domain}"
[[ "${domainInfo}" -eq 1 ]] && domainSummary
[[ "${registrantContact}" -eq 1 ]] && contactSummary "Registrant"
[[ "${adminContact}" -eq 1 ]] && contactSummary "Admin"
[[ "${techContact}" -eq 1 ]] && contactSummary "Tech"
[[ "${billingContact}" -eq 1 ]] && contactSummary "Billing"
echo "\n## Raw WHOIS Data\n\`\`\`\n${whois}\n\`\`\`"