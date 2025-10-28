# Deadface CTF — DNS Exfiltration Write-up

Challenge: We know that DEADFACE communicated back to one of their servers, but we're not sure how they did it. The junior analyst doesn't see any communications through standard channels in their network traffic. Find the message and submit the flag as deadface{flag text}.

Solution summary

1) I downloaded the provided ZIP and extracted the pcap.  
2) I opened the pcap in a packet capture viewer (e.g., Wireshark or any pcap DNS inspection tool) and filtered DNS queries.  
3) I observed multiple DNS queries and took note of suspicious-looking hostnames:
   - cDBydGFudC1UMC5jQHRj.com
   - ZGVhZGZhY2V7SXRzX0lt.com
   - aC1FdmVyeWQzdEBpbH0K.com

   These labels look like base64-encoded data used inside DNS labels (commonly used for DNS-based data exfiltration).

4) I pasted the hostname labels (stripping the .com) into CyberChef and decoded from Base64. CyberChef automatically decoded the values and revealed human-readable text.  

Decoded pieces (as seen in CyberChef):
- cDBydGFudC1UMC5jQHRj -> Its_Imp0rtant-T0.c@tch-Everyd3t@il  (piece)
- ZGVhZGZhY2V7SXRzX0lt -> deadface{Its_Im  (piece)
- aC1FdmVyeWQzdEBpbH0K -> p0rtant-T0.c@tch-Everyd3t@il}  (piece)

5) Joining the decoded parts gave the final flag: deadface{Its_Imp0rtant-T0.c@tch-Everyd3t@il}

Final answer (flag):

deadface{Its_Imp0rtant-T0.c@tch-Everyd3t@il}

Notes and mitigation

- This challenge demonstrates DNS-based data exfiltration by encoding data into DNS query labels (often Base64 or other encodings) and sending them as queries to an attacker-controlled domain.  
- Detection: Monitor for unusually long or high-entropy DNS labels, large numbers of NXDOMAIN responses, or queries to uncommon external domains.  
- Mitigation: Restrict DNS egress to approved resolvers, inspect DNS query patterns with recursive resolver logging, and use DNS-over-HTTPS/TSL controls thoughtfully.

References

- DNS data exfiltration techniques
- Using CyberChef for quick decodes
