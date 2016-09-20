#!/bin/bash

 # Path to drush.php on your computer.
DRUSH_PATH=/Applications/DevDesktop2/drush/vendor/drush/drush/drush.php

# the db name for your local server
DB_NAME=gsbmygsb0

# clone the mygsb code from acquia's git repo
git clone gsbmygsb@svn-777.prod.hosting.acquia.com:gsbmygsb.git
cd gsbmygsb

# checkout the master branch
git co master

# download a copy of the db from mygsb stage
$DRUSH_PATH @gsbmygsb.test sql-dump --structure-tables-list="cache,cache_*,history,search_*,sessions,watchdog" | gzip > gsbmygsb.sql.gz

# drop and recreate the database
mysql -uroot -proot -e "DROP DATABASE $DB_NAME;"
mysql -uroot -proot -e "CREATE DATABASE $DB_NAME;"

# import the database
pv gsbmygsb.sql.gz | gunzip | mysql -uroot -proot $DB_NAME

# comment out the follow rewrites in the .htaccess file
sed -i .bk "s/RewriteCond %{HTTPS} off/# RewriteCond %{HTTPS} off/g" docroot/.htaccess
sed -i .bk "s/RewriteCond %{HTTP:X-Forwarded-Proto} /# RewriteCond %{HTTP:X-Forwarded-Proto} /g" docroot/.htaccess
sed -i .bk "s/RewriteRule ^(.*)$ https:/# RewriteRule ^(.*)$ https:/g" docroot/.htaccess

# reinitialize the $databases settings to match your local site
cat ../dbsettings.php >> docroot/sites/default/settings.php

cd docroot

# disable the simple saml module
drush dis -y simplesaml_auth

# update the password for user1 (admin)
drush upwd --password=admin admin
