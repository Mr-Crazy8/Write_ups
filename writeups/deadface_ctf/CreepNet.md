# CreepNet — Deadface CTF

Challenge: Created By: @AstralByte. We know that DEADFACE communicated back to one of their servers, but we're not sure how they did it. The junior analyst over at De Monne Financial doesn't see any communications through standard channels in their network traffic. Find the message and submit the flag as deadface{flag text}.

Solution

1) I downloaded the provided ZIP and extracted the pcap file.
2) I opened the pcap in a packet capture viewer (for example, Wireshark) and filtered the traffic for DNS queries (dns or udp port 53).
3) I inspected DNS query names and found several suspicious-looking hostnames indicating encoded data in DNS labels. Notable queries included:
   - cDBydGFudC1UMC5jQHRj.com
   - ZGVhZGZhY2V7SXRzX0lt.com
   - aC1FdmVyeWQzdEBpbH0K.com

4) These DNS labels appear to be Base64-encoded strings. I stripped the trailing .com and pasted the label parts into CyberChef (or any Base64 decoder) and decoded them from Base64.

Decoded pieces:
- cDBydGFudC1UMC5jQHRj -> Its_Imp0rtant-T0.c@tch-Everyd3t@il
- ZGVhZGZhY2V7SXRzX0lt -> deadface{Its_Im
- aC1FdmVyeWQzdEBpbH0K -> p0rtant-T0.c@tch-Everyd3t@il}

5) Reassembling the decoded fragments revealed the full flag:

deadface{Its_Imp0rtant-T0.c@tch-Everyd3t@il}

Notes and mitigation

- This is an example of DNS-based data exfiltration: data is encoded (Base64) into DNS query labels and sent to an attacker-controlled domain.  
- Detection: Look for DNS queries with high-entropy or very long labels, many NXDOMAIN responses, or queries to unusual external domains.  
- Mitigation: Restrict DNS egress, use DNS logging and monitoring, and consider filtering or proxying external DNS.

References

- CyberChef for quick decoding
- General DNS exfiltration techniques