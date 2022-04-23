# Froxlor Installer Script

Downloading, installing and configuring froxlor with nginx + php-fpm via debian package for DEBIAN BULLSEYE (11)

## General information

Target database and privileged user 'froxroot' will be created by the script and should not exist.
The given unprivileged database user will be created for localhost and should also not exist.

A new blank froxlor database will be filled with the default sql file and a given
admin user as well as default ip/port entries for port 80 and 443 (ssl-enabled + let's encrypt).
In case the database exists, all data will be overwritten.

## Parameters

### Mysql and host information

The needed credentials are all given via a JSON parameter file as first parameter to this script.

Example:
```json
{
	"mysql": {
		"rootpasswd": "password-for-new-privileged-user-froxroot",
		"db": "database-name",
		"user": "unprivileged-mysql-user",
		"userpasswd": "password-for-unprivileged-user"
	},
	"froxlor": {
		"hostname": "installer-test.froxlor",
		"ipaddr": "2000::1",
		"adminuser": "admin",
		"adminpasswd": "froxlor-admin-password"
	}
}
```

### Exported froxlor settings

For the settings-adjustments, a prior exported froxlor-settings file is optional and can be passed as 
second parameter to this script.

To create such an export file. Login to another froxlor installation from which the settings should be exported
and navigate to Settings -> Import/Export.

## Run script

Make sure the script is executable on the server where it is run. And then run the script with given parameters

```bash
$ chmod +x install-froxlor.sh
$ ./install-froxlor.sh server-params.json froxlor-settings.json
```

Authors: froxlor GmbH, 2022

Hostname must be a valid domainname, which is reachable via Internet.
If nameserver provides a IPV6 for the main domain, then this ip must be used for configuration, because "Let's Encrypt" uses IPv6 by default.

Customer name length must be minimum 2 characters.
