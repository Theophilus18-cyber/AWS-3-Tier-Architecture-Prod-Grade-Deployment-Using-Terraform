#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>Web App Working - Environment: ${var.environment}</h1>" > /var/www/html/index.html