#!/bin/bash

# Write the database.ini file
cat <<EOL > /var/www/html/omeka-s/config/database.ini
host = "$MYSQL_HOST"
user = "$MYSQL_USER"
password = "$MYSQL_PASSWORD"
dbname = "$MYSQL_DATABASE"
EOL

# Start Apache in the foreground
exec apache2-foreground
