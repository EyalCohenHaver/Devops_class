#!/bin/bash
docker build . -t pyapp
docker run -p 5000:5000 -d --name app pyapp