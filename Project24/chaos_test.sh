C=shlok-container
URL=http://localhost:8080
ts() { date '+%Y-%m-%d %H:%M:%S'; }
check() { echo "$(ts)  HTTP $(curl -s -o /dev/null -w '%{http_code}' -m 5 $URL)"; }
status() { echo "$(ts)  container: $(sudo docker inspect -f '{{.State.Status}}' $C)"; }
echo "INCIDENT LOG - Manual Chaos Test (service: $C, image shlok-docker-app, port 8080)"
echo
echo "1. BASELINE (healthy)"
status
check
echo
echo "2. FAULT INJECTED: docker stop $C"
S=$(date +%s)
sudo docker stop $C > /dev/null
echo "$(ts)  stop issued"
echo
echo "3. FAILURE OBSERVED"
sleep 3
status
check
echo
echo "4. RECOVERY: docker start $C"
sudo docker start $C > /dev/null
echo "$(ts)  start issued"
echo
echo "5. RECOVERY VERIFIED"
sleep 3
status
check
echo
echo "Total time from stop to verified recovery: $(( $(date +%s) - S )) seconds"
