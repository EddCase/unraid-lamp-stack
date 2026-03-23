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

### 1. Clone the repository

```bash
git clone https://github.com/EddCase/unraid-lamp-stack.git
cd unraid-lamp-stack
```

### 2. Run the setup script (Windows)

```
setup.bat
```

This will:
- Rename dotfiles from their `.txt` versions to their proper names
- Open `.env` in Notepad for you to fill in your settings
- Print next steps for deploying on UnRAID

### 3. Fill in your `.env` file

The following fields are required:

```ini
WEBSERVER_IP=           # Available IP on your local network e.g. 192.168.0.23
MYSQL_ROOT_PASSWORD=    # Root password for MariaDB
MYSQL_PASSWORD=         # Password for the lampstack database user
```

The following fields have sensible defaults but can be changed:

```ini
APPDATA_PATH=/mnt/user/appdata/LampStack   # Where to store persistent data
TZ=Europe/London                            # Your timezone
HTTP_PORT=80                                # HTTP port
HTTPS_PORT=443                              # HTTPS port
PMA_PORT=8080                               # phpMyAdmin port
```

### 4. Create the appdata folder structure on UnRAID

Open a terminal on your UnRAID server and run:

```bash
mkdir -p /mnt/user/appdata/LampStack/websites/default
mkdir -p /mnt/user/appdata/LampStack/database
mkdir -p /mnt/user/appdata/LampStack/logs/apache
mkdir -p /mnt/user/appdata/LampStack/logs/php
mkdir -p /mnt/user/appdata/LampStack/config/vhosts
```

> If you changed `APPDATA_PATH` in your `.env`, replace `/mnt/user/appdata/LampStack` with your chosen path.

### 5. Deploy via Compose Manager

1. Copy the repository folder to your UnRAID server
2. In UnRAID go to **Plugins → Compose Manager**
3. Click **Add New Stack**
4. Point it at your `docker-compose.yml` file
5. Start the stack

### 6. Verify the install

Visit `http://YOUR_WEBSERVER_IP` in your browser. You should see the LAMP Stack landing page confirming all components are running.

phpMyAdmin is available at `http://YOUR_WEBSERVER_IP:8080`

---

## Adding a New Site

### 1. Create a folder for the site

On your UnRAID server, create a folder for the site's files:

```
/mnt/user/appdata/LampStack/websites/mysite/
```

### 2. Create a virtual host config

Create a new `.conf` file in `/mnt/user/appdata/LampStack/config/vhosts/` based on this template:

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

Add a custom DNS record in Pi-hole pointing your chosen domain at the server IP:

```
mysite.local → 192.168.0.x
```

In Pi-hole this is done via **Local DNS → DNS Records** or by adding a line to:
```
/mnt/user/VM/Dockers/PiHole/dnsmasq/02-custom.conf
```

```
address=/mysite.local/192.168.0.x
```

Then restart Pi-hole's DNS resolver.

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

Open phpMyAdmin at `http://YOUR_WEBSERVER_IP:8080` and:

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
├── setup.bat                         # Windows first-time setup script
├── env.txt                           # Rename to .env and fill in your settings
├── env.example.txt                   # Example .env for reference
├── gitignore.txt                     # Rename to .gitignore
├── README.md                         # This file
├── config/
│   ├── apache/
│   │   ├── httpd.conf                # Custom Apache configuration
│   │   └── vhosts/
│   │       └── default.conf          # Default virtual host
│   └── php/
│       └── php.ini                   # Custom PHP configuration
└── websites/
    └── default/
        ├── index.html                # Default landing page
        └── lamp-icon.png             # Stack icon
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
