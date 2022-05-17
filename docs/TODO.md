# TODOs list

## Add monitoring 

There should be monitoring added to this solution consisting at least of Cloudwatch, Prometheus and Alertmanager.

## Improve database security

Currently there is only a single account to access the whole database (`psqladm`). It is the admin account of the database and the account used by umami to read/write on the umami database, this is not secure. There should be an additional account with only read/write access to the umami database used by the umami servers.

## Initialize the database

There is one manual step currently required in the process which is to initialize the database using a script provided by Umami. This script will drop all tables in the target database and create the skeleton of the umami database. This causes an issue where the script cannot be run as part of the ansible playbook as this would wipe the database every time a new server is added to the stack.

I could include a short bash script to conditonally run the script if the database isn't ready as part of the umami-server playbook. Or I could simply consider the setting up of the database as being something to do once when first setting up the stack then relying on snapshots/backups if I ever need to recreate the database for whatever reason.

## Building Umami

Part of the process to configure the umami servers involve building the application using `npm run build`. This takes a long time and it requires a .env file including the database password which is then deleted at the end of the process. This feel convoluted and I'm sure this could be improved somehow.

## Version pinning

Building starts with cloning the repo. Currently I'm just cloning the whole repo and building from the master branch which is really bad practice. I should checkout a specific ref or even better, download and extract one of the provided releases.
