#!/bin/bash

# Pull docker image
# Docker pull dojustin/mysite:latest
# Kill old running container (to clear host port)
echo "stopping contianer"
docker stop eggroll

# Prunes latest
docker system prune -f -a

# Pull docker image post prune
echo "pulling image"
docker pull dojustin/mysite:latest

# Run new image
echo "run image eggroll"
docker run -d --name eggroll -p 80:80 dojustin/mysite:latest
