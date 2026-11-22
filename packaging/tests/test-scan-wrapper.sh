#!/bin/sh
# Test di packaging/templates/sentinelcore-scan (modalita' --check: valida
# senza eseguire nulla, quindi gira senza root e senza nmap installato).
#   sh packaging/tests/test-scan-wrapper.sh
set -u

SCAN="$(cd "$(dirname "$0")/../templates" && pwd)/sentinelcore-scan"
pass=0
fail=0

ok() { # ok "descrizione" args...
    desc=$1; shift
    if sh "$SCAN" --check "$@" >/dev/null 2>&1; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1)); echo "FAIL (doveva passare): $desc -> $*"
    fi
}

no() { # no "descrizione" args...
    desc=$1; shift
    if sh "$SCAN" --check "$@" >/dev/null 2>&1; then
        fail=$((fail + 1)); echo "FAIL (doveva essere rifiutato): $desc -> $*"
    else
        pass=$((pass + 1))
    fi
}

# --- comandi che l'applicazione genera davvero -------------------------------
ok "discovery di default" nmap -sV -T1 --max-retries=2 -p- -sU --top-ports=100 -O --osscan-limit -oX - -- 10.0.0.0/24 192.168.1.5
ok "range scan" nmap -sV -T4 --top-ports=100 --max-retries=2 -O --osscan-limit -oX - -- 10.0.0.1-50
ok "ping scan" nmap -sn -PR -oX - -- 10.0.0.0/24
ok "porte con valore separato" nmap -p 22,80,443 --top-ports 100 -oX - -- host.example.com
ok "ipv6" nmap -6 -sn -oX - -- fe80::1
ok "arp-scan" arp-scan --interface=eth0 --retry=3 --timeout=500 -- 192.168.1.0/24
ok "arp-scan localnet" arp-scan --interface=eth0 --localnet

# --- iniezioni sul target ----------------------------------------------------
no "target come opzione" nmap -oX - -- -iL /etc/shadow
no "target -oN" nmap -oX - -- 10.0.0.1 -oN /etc/cron.d/x
no "target senza separatore" nmap -sn 10.0.0.1
no "nessun target" nmap -sn -oX - --
no "target con metacaratteri" nmap -sn -oX - -- '10.0.0.1;id'
no "target con sostituzione" nmap -sn -oX - -- '$(id)'
no "target con spazio" nmap -sn -oX - -- '10.0.0.1 -oN /x'
no "target con path" nmap -sn -oX - -- ../../etc/shadow
no "target con slash non-maschera" nmap -sn -oX - -- a/b
no "target con slash doppio" nmap -sn -oX - -- 10.0.0.0//24
no "maschera con lettere" nmap -sn -oX - -- 10.0.0.0/ab
ok "maschera decimale" arp-scan --interface=eth0 -- 10.0.0.0/255.255.255.0
no "arp-scan target come opzione" arp-scan --interface=eth0 -- --file=/etc/shadow
no "arp-scan senza target" arp-scan --interface=eth0 --retry=3

# --- opzioni non ammesse -----------------------------------------------------
for opt in -oN -oG -oA -oS -iL -iR --script=vuln --script -sC -A --datadir=/tmp \
           --resume --stylesheet=x --excludefile=x --servicedb=x --proxies --append-output; do
    no "opzione vietata $opt" nmap "$opt" x -oX - -- 10.0.0.1
done
no "-oX su file" nmap -oX /tmp/out -- 10.0.0.1
no "-oX senza valore" nmap -oX
no "valore con metacaratteri" nmap -p '22;id' -oX - -- 10.0.0.1
no "valore --opt= sospetto" nmap --top-ports='1 -oN /x' -oX - -- 10.0.0.1
no "arp-scan --file" arp-scan --file=/etc/shadow -- 10.0.0.1
no "arp-scan interfaccia con path" arp-scan --interface=../x -- 10.0.0.1
no "arp-scan opzione ignota" arp-scan --pcapsavefile=/tmp/x -- 10.0.0.1

# --- tool e struttura --------------------------------------------------------
no "tool non consentito" bash -c id
no "tool assoluto" /usr/bin/nmap -sn -- 10.0.0.1
no "nessun argomento"
no "tool vuoto" ""

# troppi target
targets=""
i=0
while [ "$i" -le 64 ]; do targets="$targets 10.0.0.$i"; i=$((i + 1)); done
# shellcheck disable=SC2086
no "oltre 64 target" nmap -sn -oX - -- $targets

echo "passati: $pass  falliti: $fail"
[ "$fail" -eq 0 ]
