#!/bin/zsh --no-rcs

readonly whois=$(whois "${1}" | tr -d '\r')
output="# WHOIS ${1}"

# Check if IP Address
[[ "${1}" != *[[:alpha:]]* || "${1}" == *":"* ]] && summary=0

# Domain Information
if [[ $domainInfo -eq 1 ]]; then
	emptyCheck=$(awk '/^Domain Name/ && !seen[$0]++ { arr[0] = "* **Domain Name**: " tolower($3) }
	/^Registrar:[^$]/ && !seen[$0]++ { $1=""; arr[1] = "* **Registrar**:" $0 }
	/^Creation Date/ && !seen[$0]++ { arr[2] = "* **Creation Date**: " substr($3,0,10) }
	/Expiry Date/ && !seen[$0]++ { arr[3] = "* **Expiry Date**: " substr($4,0,10) }
	/^Updated Date/ && !seen[$0]++ { arr[4] = "* **Renewed Date**: " substr($3,0,10) }
	END {
		for (i = 0; i < length(arr); i++)
			print arr[i]
	}' <<< "${whois}")
	[[ -n "${emptyCheck}" ]] && output+="\n\n### Domain Information\n${emptyCheck}"

	emptyCheck=$(awk '/^Name Server/ && !seen[tolower($0)]++ { print "* **Name Server**:", $3 }' <<< "${whois}")
	[[ "${emptyCheck}" != "* **Name Server**: " ]] && output+="\n${emptyCheck}"
	
	emptyCheck=$(awk '/^Registrar Abuse Contact Email/ && !seen[$0]++ { print "* **Registrar Abuse Contact Email**:", tolower($5) }' <<< "${whois}")
	[[ -n "${emptyCheck}" ]] && output+="\n${emptyCheck}"
fi

# Contact Information
if [[ $registrantContact -eq 1 ]]; then
	emptyCheck=$(awk '/^Registrant/ && !seen[$0]++ { if ($0 !~ /REDACTED/ && $0 !~ /(:$|: $)/ && $0 !~ /Email[^@]*$/) print "*", $0 }' <<< "${whois}")
	[[ -n "${emptyCheck}" ]] && output+="\n\n### Registrant Contact\n${emptyCheck}"
fi
if [[ $adminContact -eq 1 ]]; then
	emptyCheck=$(awk '/^Admin/ && !seen[$0]++ { if ($0 !~ /REDACTED/ && $0 !~ /(:$|: $)/ && $0 !~ /Email[^@]*$/) print "*", $0 }' <<< "${whois}")
	[[ -n "${emptyCheck}" ]] && output+="\n\n### Administrative Contact\n${emptyCheck}"
fi
if [[ $techContact -eq 1 ]]; then
	emptyCheck=$(awk '/^Tech/ && !seen[$0]++ { if ($0 !~ /REDACTED/ && $0 !~ /(:$|: $)/ && $0 !~ /Email[^@]*$/) print "*", $0 }' <<< "${whois}")
	[[ -n "${emptyCheck}" ]] && output+="\n\n### Technical Contact\n${emptyCheck}"
fi
if [[ $billingContact -eq 1 ]]; then
	emptyCheck=$(awk '/^Billing/ && !seen[$0]++ { if ($0 !~ /REDACTED/ && $0 !~ /(:$|: $)/ && $0 !~ /Email[^@]*$/) print "*", $0 }' <<< "${whois}")
	[[ -n "${emptyCheck}" ]] && output+="\n\n### Billing Contact\n${emptyCheck}"
fi

# Raw WHOIS Data
output+=$(echo "\n\n## Raw WHOIS Data\n
\`\`\`
${whois}
\`\`\`")

# Export to File or Text View
if [[ "${textView}" -eq 1 ]]; then
    echo "${output}"
else
    mkdir -p ${alfred_workflow_cache}
    echo "${whois}" > ${alfred_workflow_cache}/whois.txt
fi