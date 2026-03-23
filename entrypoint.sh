#!/bin/bash
# =============================================================================
# LAMP Stack - Container Entrypoint Script
# Runs every time the container starts, before Apache launches
# =============================================================================

# Exit immediately if any command fails
set -e

echo "=== LAMP Stack Starting Up ==="

# =============================================================================
# PERMISSIONS FIX
# Only fix ownership on folders Apache needs to write to.
# We deliberately do NOT chown /var/www/html - that folder is owned by
# nobody:users on UnRAID which allows Windows network share access.
# Apache only needs read access to serve files, not ownership.
# =============================================================================

echo "--- Setting permissions on mounted volumes ---"

# Apache needs to write logs
chown -R www-data:www-data /var/log/apache2
chown -R www-data:www-data /var/log/php

# Apache needs to read vhost configs
chown -R www-data:www-data /etc/apache2/sites-available/vhosts

# Set directory and file permissions on websites
# 755/644 means Apache can read everything, nobody:users can read/write
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

# =============================================================================
# VHOSTS CHECK
# Make sure the vhosts directory exists
# =============================================================================

echo "--- Checking virtual hosts directory ---"

if [ ! -d "/etc/apache2/sites-available/vhosts" ]; then
    echo "--- vhosts directory missing, recreating ---"
    mkdir -p /etc/apache2/sites-available/vhosts
    chown www-data:www-data /etc/apache2/sites-available/vhosts
fi

# =============================================================================
# DEFAULT SITE CHECK
# On first run, copy the baked-in default site files into the webroot
# If index.html already exists we leave it alone - don't overwrite user files
# =============================================================================

echo "--- Checking default site ---"

if [ ! -d "/var/www/html/default" ]; then
    echo "--- Creating default site directory ---"
    mkdir -p /var/www/html/default
fi

if [ ! -f "/var/www/html/default/index.html" ]; then
    echo "--- First run detected, copying default site files ---"
    cp -r /var/www/defaults/. /var/www/html/default/
    echo "--- Default site files copied ---"
else
    echo "--- Default site already exists, leaving untouched ---"
fi

# =============================================================================
# HAND OFF TO APACHE
# =============================================================================

echo "--- All checks complete, starting Apache ---"
echo "=== LAMP Stack Ready ==="

exec apache2-foreground
