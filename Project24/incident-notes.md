# Incident Notes - Project 24: Manual Chaos Test
 
Goal: record recovery from failure.
 
## Summary
A planned (manual) failure was injected into a running web service: the Docker container shlok-container (image shlok-docker-app, nginx, host port 8080 to container port 80) on the Ubuntu VM. The service was stopped, the outage was observed, the service was restarted and recovery was verified.
 
## Timeline (VM clock, 2026-11-25)
| Time     | Event |
|----------|-------|
| 04:57:31 | Baseline: container running, HTTP 200 on http://localhost:8080 |
| 04:57:32 | Fault injected: sudo docker stop shlok-container |
| 04:57:35 | Failure observed: container exited, HTTP 000 (no connection) |
| 04:57:35 | Recovery started: sudo docker start shlok-container |
| 04:57:38 | Recovery verified: container running, HTTP 200 |
 
Total time from stop to verified recovery: 7 seconds (includes two 3-second waits built into the test script).
 
## Impact
The web page on port 8080 was unreachable between the stop and the restart. Only shlok-container was touched. No other containers or AWS resources were changed.
 
## Detection
curl against http://localhost:8080 returned HTTP 000 and docker inspect showed the state as exited.
 
## Recovery steps
1. docker start shlok-container
2. Waited 3 seconds.
3. Checked docker inspect (running) and curl (HTTP 200).
 
## Root cause
Intentional: the container was stopped manually for the chaos test.
 
## Lessons and improvements
- Recovery was manual. A restart policy (docker run --restart unless-stopped) would bring the container back by itself after a crash or reboot.
- A health check or monitoring alarm would detect the outage without someone running curl.
 
## Evidence
- incident-log.txt: full timestamped output of chaos_test.sh.
- chaos_test.sh: the script that ran the test.
