#!/bin/bash
# =============================================================================
# LAMP Stack - Container Entrypoint Script
# Runs every time the container starts, before Apache launches
# =============================================================================

# Exit immediately if any command fails
set -e

echo "=== LAMP Stack Starting Up ==="

# =============================================================================
# PERMISSIONS
# We set permissions carefully here to satisfy two requirements:
#
#   1. Apache (www-data) must be able to READ website files and configs
#   2. UnRAID user (nobody:users) must be able to READ AND WRITE via
#      Windows network share
#
# Strategy:
#   - websites and vhosts: 777 so both Apache and Windows can read/write
#   - logs: owned by www-data so Apache can write to them
#   - We NEVER chown /var/www/html - that would break Windows share access
# =============================================================================

echo "--- Setting permissions ---"

# Websites folder - 777 so Apache can read AND Windows can write
# We do NOT chown this - nobody:users ownership must be preserved
find /var/www/html -type d -exec chmod 777 {} \;
find /var/www/html -type f -exec chmod 777 {} \;

# Vhosts config folder - 777 so Apache can read AND Windows can write new configs
# We do NOT chown this either
chmod -R 777 /etc/apache2/sites-available/vhosts

# Logs - Apache needs to write these so www-data ownership is correct here
chown -R www-data:www-data /var/log/apache2
chown -R www-data:www-data /var/log/php
chmod -R 755 /var/log/apache2
chmod -R 755 /var/log/php

echo "--- Permissions set ---"

# =============================================================================
# VHOSTS CHECK
# Make sure the vhosts directory exists
# =============================================================================

echo "--- Checking virtual hosts directory ---"

if [ ! -d "/etc/apache2/sites-available/vhosts" ]; then
    echo "--- vhosts directory missing, recreating ---"
    mkdir -p /etc/apache2/sites-available/vhosts
    chmod 777 /etc/apache2/sites-available/vhosts
fi

# =============================================================================
# DEFAULT SITE
# Always copy the baked-in defaults to make sure the latest version is live
# We use rsync-style logic - only overwrite if the baked-in version is newer
# This means updates to the image are reflected without wiping user changes
# to OTHER files in the default folder
# =============================================================================

echo "--- Checking default site ---"

if [ ! -d "/var/www/html/default" ]; then
    echo "--- Creating default site directory ---"
    mkdir -p /var/www/html/default
    chmod 777 /var/www/html/default
fi

# Always copy index.html and lamp-icon.png from baked-in defaults
# These are our managed files - always keep them current with the image
echo "--- Updating default site files ---"
cp /var/www/defaults/index.html /var/www/html/default/index.html
cp /var/www/defaults/lamp-icon.png /var/www/html/default/lamp-icon.png
echo "--- Default site files updated ---"

# =============================================================================
# HAND OFF TO APACHE
# =============================================================================

echo "--- All checks complete, starting Apache ---"
echo "=== LAMP Stack Ready ==="

exec apache2-foreground
