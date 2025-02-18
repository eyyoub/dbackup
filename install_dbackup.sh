#!/bin/bash

# Create non-login user
useradd -r -s /bin/false dbackup

# Create necessary directories
mkdir -p /etc/dbackup
mkdir -p /home/$(logname)/dbackup
mkdir -p /home/$(logname)/dbackup/backup
mkdir -p /var/log/dbackup

# Set permissions
chown -R dbackup:dbackup /home/$(logname)/dbackup
chown -R dbackup:dbackup /var/log/dbackup
chmod 755 /home/$(logname)/dbackup
chmod 755 /var/log/dbackup

# Copy backup script
cp dbackup.sh /usr/local/bin/
chmod 755 /usr/local/bin/dbackup.sh

# Copy service and timer files
cp dbackup.service /etc/systemd/system/
cp dbackup.timer /etc/systemd/system/
cp dbackup-archive.timer /etc/systemd/system/

# Reload systemd
systemctl daemon-reload

# Enable and start services
systemctl enable dbackup.timer
systemctl enable dbackup-archive.timer
systemctl start dbackup.timer
systemctl start dbackup-archive.timer