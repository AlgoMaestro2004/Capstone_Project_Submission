# Project5: Secure Linux Server Permissions

## Goal
Apply user-based access restrictions on a shared folder.

## Setup
- Groups: shlok-devs (read and write), shlok-readers ( read only)
- Users: dev1 (in shlok-devs), reader1 (in shlok-readers), outsider (in no group)
- Folder: /srv/shlok-project5, owner root, group shlok-devs, mode 770

## Results:

--dev1 had write permission allowed
--reader1 had read allowed and write disabled/denied
--outsider had read,write and list permissions all disabled/denied

##Why this works as it does:
-- chmod 770 gives devs full permission
--ACL gives readers read and enter access
--Users outside these groups like outsider have no permission
