# LAMP Stack — Custom UnRAID Docker Template

![LAMP Stack Icon](websites/default/lamp-icon.png)

A custom LAMP stack Docker image for local PHP web development on UnRAID.
Built for experimenting with WordPress, Drupal, Joomla and general PHP development.
Supports multiple sites simultaneously via Apache virtual hosts, with a built-in
web-based site manager for creating and deleting sites with a single click.

---

## Stack Components

| Component | Version | Purpose |
|---|---|---|
| Apache | 2.4 | Web server |
| PHP | 8.3 | Server-side scripting |
| Composer | Latest | PHP package manager |
| MariaDB | 11 | Database server |
| phpMyAdmin | Latest | Database management UI |

### PHP Extensions Included

`gd` `pdo` `pdo_mysql` `mysqli` `zip` `exif` `opcache` `intl` `bcmath` `soap` `xml` `mbstring` `curl` `imagick` `redis` `xdebug`

---

## Requirements

- UnRAID server with Docker support
- [Compose Manager](https://forums.unraid.net/topic/114415-plugin-docker-compose-manager/) plugin installed
- A fixed IP available on your local network
- Pi-hole (required for the site manager's automatic DNS management)

---

## Quick Start

### 1. Deploy via Compose Manager

In UnRAID go to **Plugins → Compose Manager** and add a new stack pointing at:

```
https://raw.githubusercontent.com/EddCase/unraid-lamp-stack/main/docker-compose.yml
```

### 2. Create the appdata folder structure

SSH into your UnRAID server and run:

```bash
mkdir -p /mnt/user/appdata/LampStack/websites/default
mkdir -p /mnt/user/appdata/LampStack/database
mkdir -p /mnt/user/appdata/LampStack/logs/apache
mkdir -p /mnt/user/appdata/LampStack/logs/php
mkdir -p /mnt/user/appdata/LampStack/config/vhosts
mkdir -p /mnt/user/appdata/LampStack/config/apache
mkdir -p /mnt/user/appdata/LampStack/config/php
mkdir -p /mnt/user/appdata/LampStack/config/env
```

Copy the config files from the repo into the new folders:

```bash
# Copy Apache and PHP configs from the repo to your appdata
cp config/apache/httpd.conf /mnt/user/appdata/LampStack/config/apache/httpd.conf
cp config/php/php.ini /mnt/user/appdata/LampStack/config/php/php.ini
cp config/env/.env.example /mnt/user/appdata/LampStack/config/env/.env
```

> If you changed `APPDATA_PATH`, replace `/mnt/user/appdata/LampStack` with your chosen path.

### 3. Configure your environment

Edit `/mnt/user/appdata/LampStack/config/env/.env` and fill in your values:

```ini
SERVER_IP=              # The IP your LAMP stack is accessible at e.g. 192.168.0.23
PIHOLE_HOST=            # Pi-hole URL e.g. http://192.168.0.6
PIHOLE_API_KEY=         # Pi-hole v6 app password (Settings → API → App password)
```

Then edit the Compose Manager ENV file and fill in the required fields:

```ini
WEBSERVER_IP=           # Same IP as SERVER_IP above e.g. 192.168.0.23
MYSQL_ROOT_PASSWORD=    # Root password for MariaDB
MYSQL_PASSWORD=         # Password for the lampstack database user
```

Optional fields with sensible defaults:

```ini
APPDATA_PATH=/mnt/user/appdata/LampStack   # Where to store persistent data
LAMP_SUBNET=172.21.0.0/24                  # Internal Docker subnet - change if conflicts exist
TZ=Europe/London                            # Your timezone
PMA_PORT=8080                               # phpMyAdmin port
```

> If you get a subnet conflict error on first run, check existing networks with `docker network ls` and set `LAMP_SUBNET` to an unused subnet.

### 4. Enable Pi-hole app_sudo (one-time setup)

The site manager uses the Pi-hole v6 API to manage DNS records automatically. Run this once to grant the required permissions:

```bash
docker exec PiHole pihole-FTL --config webserver.api.app_sudo true
```

This setting persists across container restarts.

### 5. Start the stack

Click Start in Compose Manager. On first run it will:
- Pull `eddcase/lamp-stack` from DockerHub
- Pull `mariadb:11` from DockerHub
- Pull `phpmyadmin:latest` from DockerHub
- Start all three containers

### 6. Verify the install

Visit `http://YOUR_WEBSERVER_IP` — you should see the LAMP Stack site manager.

phpMyAdmin is available at `http://YOUR_UNRAID_IP:8080`

---

## Site Manager

The default landing page at `http://YOUR_WEBSERVER_IP` is a built-in site manager. It handles everything needed to create or delete a local development site — no manual file editing or Pi-hole configuration required.

### Creating a site

Enter a site name and click **Create Site**. The site manager will automatically:

1. Create the site folder at `/var/www/html/sitename/` with a placeholder `index.html`
2. Write an Apache virtual host config for `sitename.local`
3. Add a DNS record in Pi-hole pointing `sitename.local` at your server IP
4. Gracefully reload Apache — the site is live immediately

### Deleting a site

Click **Delete** on any site card and confirm. The site manager will automatically remove the site folder, vhost config, and Pi-hole DNS record.

### Site name rules

- Letters, numbers, hyphens and underscores only
- Cannot be `default`
- Cannot start with `000`

---

## Installing WordPress

### 1. Create a new site via the site manager

Visit `http://YOUR_WEBSERVER_IP` and create a site named `wordpress`. This sets up the folder, vhost config and DNS record automatically.

### 2. Download WordPress

Download WordPress from [wordpress.org](https://wordpress.org/download/) and extract it into:

```
/mnt/user/appdata/LampStack/websites/wordpress/
```

### 3. Create a database

Open phpMyAdmin at `http://YOUR_UNRAID_IP:8080` and:

1. Click **New** in the left sidebar
2. Enter a database name e.g. `wordpress`
3. Click **Create**

### 4. Run the WordPress installer

Visit `http://wordpress.local` and follow the WordPress setup wizard.

When asked for database details use:

```
Database Name:  wordpress
Username:       lampstack   (or your MYSQL_USER value)
Password:       (your MYSQL_PASSWORD value)
Database Host:  mariadb
Table Prefix:   wp_
```

> The database host is `mariadb` not `localhost` — this is the container name on the internal Docker network.

---

## File Structure

### GitHub Repository

```
unraid-lamp-stack/
├── Dockerfile                        # Builds the custom Apache/PHP/Composer image
├── docker-compose.yml                # Runs the full stack on UnRAID
├── entrypoint.sh                     # Container startup script
├── README.md                         # This file
├── config/
│   ├── apache/
│   │   ├── httpd.conf                # Custom Apache configuration (KeepAlive, compression, caching)
│   │   └── vhosts/
│   │       └── 000_default.conf      # Default virtual host (fallback for direct IP access)
│   ├── php/
│   │   └── php.ini                   # Custom PHP configuration (OPcache, XDebug, upload limits)
│   └── env/
│       └── .env.example              # Site manager environment config template
└── websites/
    └── default/
        ├── index.php                 # Default landing page and site manager
        └── lamp-icon.png             # Stack icon
```

### UnRAID Appdata

```
LampStack/
├── websites/                         # Site files - one folder per site
│   ├── default/                      # Default landing page and site manager
│   ├── wordpress/                    # Example WordPress site
│   └── mysite/                       # Example custom site
├── database/                         # MariaDB data files (do not edit manually)
├── logs/
│   ├── apache/                       # Apache access and error logs
│   └── php/                          # PHP error and XDebug logs
└── config/
    ├── vhosts/                       # Virtual host configs - one .conf per site
    │   ├── wordpress.conf
    │   └── mysite.conf
    ├── apache/
    │   └── httpd.conf                # Apache config - edit directly, restart to apply
    ├── php/
    │   └── php.ini                   # PHP config - edit directly, restart to apply
    └── env/
        └── .env                      # Site manager environment config (never commit this)
```

> `config/apache/`, `config/php/` and `config/env/` are mounted as Docker volumes. Edit files directly on the host — no image rebuild needed, just restart the container.

---

## Performance Notes

- **OPcache** is enabled by default for PHP bytecode caching
- **mod_deflate** is enabled for gzip compression
- **mod_expires** is enabled for browser caching of static assets
- **XDebug** is installed but set to `trigger` mode — it only activates when deliberately triggered via a browser extension, so normal page loads are unaffected

---

## DockerHub

The pre-built image is available on DockerHub:

```
docker pull eddcase/lamp-stack:latest
```

[hub.docker.com/r/eddcase/lamp-stack](https://hub.docker.com/r/eddcase/lamp-stack)

---

## Building the Image Yourself

If you want to build the image locally rather than pulling from DockerHub:

```bash
git clone https://github.com/EddCase/unraid-lamp-stack.git
cd unraid-lamp-stack
docker build -t eddcase/lamp-stack .
```

To push to DockerHub after making changes:

```bash
docker build -t eddcase/lamp-stack:latest .
docker push eddcase/lamp-stack:latest
```

---

## Roadmap

- [ ] HTTPS support via NPM proxy host for external access
- [ ] Redis container (optional add-on)
- [ ] Gitea + Code-server integration

---

## Maintainer

- GitHub: [github.com/EddCase](https://github.com/EddCase)
- DockerHub: [hub.docker.com/u/eddcase](https://hub.docker.com/u/eddcase)

---

## Licence

MIT — free to use, modify and share. Attribution appreciated but not required.
