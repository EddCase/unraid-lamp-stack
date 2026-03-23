# LAMP Stack — Custom UnRAID Docker Template

![LAMP Stack Icon](websites/default/lamp-icon.png)

A custom LAMP stack Docker image for local PHP web development on UnRAID.
Built for experimenting with WordPress, Drupal, Joomla and general PHP development.
Supports multiple sites simultaneously via Apache virtual hosts.

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
- Pi-hole or similar for local DNS (recommended for multi-site setup)

---

## Quick Start

### 1. Deploy via Compose Manager

In UnRAID go to **Plugins → Compose Manager** and add a new stack pointing at:

```
https://raw.githubusercontent.com/EddCase/unraid-lamp-stack/main/docker-compose.yml
```

### 2. Configure your environment

Compose Manager will load the stack with default values from `env.example.txt`.
Edit the ENV file in Compose Manager and fill in the required fields:

```ini
WEBSERVER_IP=           # Available IP on your local network e.g. 192.168.0.23
MYSQL_ROOT_PASSWORD=    # Root password for MariaDB
MYSQL_PASSWORD=         # Password for the lampstack database user
```

Optional fields with sensible defaults:

```ini
APPDATA_PATH=/mnt/user/appdata/LampStack   # Where to store persistent data
LAMP_SUBNET=172.21.0.0/24                  # Internal Docker subnet - change if conflicts exist
TZ=Europe/London                            # Your timezone
HTTP_PORT=80                                # HTTP port
HTTPS_PORT=443                              # HTTPS port
PMA_PORT=8080                               # phpMyAdmin port
```

> If you get a subnet conflict error on first run, check your existing networks with `docker network ls` and set `LAMP_SUBNET` to an unused subnet.

### 3. Create the appdata folder structure

SSH into your UnRAID server and run:

```bash
mkdir -p /mnt/user/appdata/LampStack/websites/default
mkdir -p /mnt/user/appdata/LampStack/database
mkdir -p /mnt/user/appdata/LampStack/logs/apache
mkdir -p /mnt/user/appdata/LampStack/logs/php
mkdir -p /mnt/user/appdata/LampStack/config/vhosts
```

> If you changed `APPDATA_PATH`, replace `/mnt/user/appdata/LampStack` with your chosen path.

### 4. Start the stack

Click Start in Compose Manager. On first run it will:
- Pull `eddcase/lamp-stack` from DockerHub
- Pull `mariadb:11` from DockerHub
- Pull `phpmyadmin:latest` from DockerHub
- Start all three containers

### 5. Verify the install

Visit `http://YOUR_WEBSERVER_IP` — you should see the LAMP Stack landing page.

phpMyAdmin is available at `http://YOUR_UNRAID_IP:8080`

---

## Adding a New Site

### 1. Create a folder for the site

```
/mnt/user/appdata/LampStack/websites/mysite/
```

### 2. Create a virtual host config

Create a new `.conf` file in `/mnt/user/appdata/LampStack/config/vhosts/`:

```apache
<VirtualHost *:80>
    ServerName mysite.local
    DocumentRoot /var/www/html/mysite

    <Directory /var/www/html/mysite>
        AllowOverride All
        Require all granted
        Options Indexes FollowSymLinks
    </Directory>

    CustomLog /var/log/apache2/mysite-access.log combined
    ErrorLog /var/log/apache2/mysite-error.log
</VirtualHost>
```

### 3. Add a Pi-hole DNS entry

Add a custom DNS record pointing your chosen domain at the server IP.

Via Pi-hole web interface: **Settings → Local DNS → DNS Records**

Or add directly to your dnsmasq config:
```
address=/mysite.local/192.168.0.x
```

Then reload Pi-hole DNS:
```bash
docker exec PiHole pihole reloaddns
```

### 4. Restart the stack

In Compose Manager, restart the stack. Apache will pick up the new vhost config automatically.

### 5. Visit your new site

Open `http://mysite.local` in your browser.

---

## Installing WordPress

### 1. Add a new site following the steps above

Use a domain like `wordpress.local`.

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
│   │   ├── httpd.conf                # Custom Apache configuration
│   │   └── vhosts/
│   │       └── default.conf          # Default virtual host
│   └── php/
│       └── php.ini                   # Custom PHP configuration
├── websites/
│   └── default/
│       ├── index.html                # Default landing page
│       └── lamp-icon.png             # Stack icon
└── unraid-template/
    ├── LampStack.xml                 # UnRAID Compose Manager template
    └── LampStack.png                 # Template icon
```

### UnRAID Appdata

```
LampStack/
├── websites/                         # Site files - one folder per site
│   ├── default/                      # Default landing page
│   ├── wordpress/                    # Example WordPress site
│   └── mysite/                       # Example custom site
├── database/                         # MariaDB data files (do not edit manually)
├── logs/
│   ├── apache/                       # Apache access and error logs
│   └── php/                          # PHP error and xdebug logs
└── config/
    └── vhosts/                       # Virtual host configs - one .conf per site
        ├── wordpress.conf
        └── mysite.conf
```

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

- [ ] Site management GUI — web based tool for creating new virtual hosts and Pi-hole DNS entries automatically
- [ ] Landing page dashboard — auto-updating list of active sites
- [ ] HTTPS support via NPM proxy host for external access
- [ ] Redis container (optional add-on)

---

## Maintainer

**Edd Case**
- GitHub: [github.com/EddCase](https://github.com/EddCase)
- DockerHub: [hub.docker.com/u/eddcase](https://hub.docker.com/u/eddcase)

---

## Licence

MIT — free to use, modify and share. Attribution appreciated but not required.
