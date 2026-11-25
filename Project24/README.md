# Project 24 - Manual Chaos Test
 
Goal: record recovery from failure. Task: stop a service, restart it and verify recovery.
 
Files:
- chaos_test.sh: stops shlok-container, shows the failure, restarts it and verifies HTTP 200.
- incident-log.txt: timestamped output of the run.
- incident-notes.md: incident notes (timeline, impact, detection, recovery, lessons).
 
No AWS resources were created, so nothing needed destroying.
