#!/bin/bash
sudo yum update -y
sudo yum install docker -y
sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
cd /home/ec2-user/app
sudo service docker start
sudo docker-compose up