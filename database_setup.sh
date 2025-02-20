#!/bin/bash

# MySQL root password (for non-interactive execution)
# SECURITY NOTE: Better to use password prompt than hardcoding password
MYSQL_ROOT_PASS="Root Password"
DB_USER_PASS="Databases User Password"

# Create database, user, and table
sudo mysql -u root -p${MYSQL_ROOT_PASS} <<EOF
CREATE DATABASE IF NOT EXISTS serpent_surge_db;
CREATE USER IF NOT EXISTS 'serpent_db_user'@'localhost' IDENTIFIED BY '${DB_USER_PASS}';
GRANT ALL PRIVILEGES ON serpent_surge_db.* TO 'serpent_db_user'@'localhost';
FLUSH PRIVILEGES;
USE serpent_surge_db;
CREATE TABLE IF NOT EXISTS score (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name TEXT NOT NULL,
    score INT NOT NULL,
    difficulty INT NOT NULL
);
DESCRIBE score;
EOF

echo "Database and table created successfully"

# Test the new user connection
sudo mysql -u serpent_db_user -p${DB_USER_PASS} serpent_surge_db <<EOF
INSERT INTO score (name, score, difficulty) VALUES ('TestPlayer', 100, 2);
SELECT * FROM score;
EOF

echo "Test data inserted and retrieved successfully"

