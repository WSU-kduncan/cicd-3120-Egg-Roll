
## Documentation

### Part 1 - Dockerize it

- Project Overview
  - 
- Run Project Locally
  - how you installed docker + dependencies (WSL2, for example)
    - `sudo apt install docker.io`
  - how to build the container
    - `sudo docker build -t my-apache2 .`
  - how to run the container
    - `sudo docker run --rm -it -p 8080:80 ubuntu`
    - `sudo docker run --rm -it -p 8080:80 eggr0ll/mysite:latest` - if pulled from dockerhub to local
  - how to view the project (open a browser...go to ip and port...)
    - http://localhost:8080/
    - http://127.0.0.1:8080
  
### Part 2 - GitHub Actions and DockerHub  
  
- Create DockerHub public repo
  - process to create
    - access Docker Hub
    - select create repo
    - add name/description
    - select create
- How to authenticate with DockerHub via CLI using Dockhub credentials
  - Access account settings and click on security
  - Create "New Access Token" and select read, write, and delete
  - Save the token in a secure location for later access
  - In WSL2, enter `docker login -u eggr0ll` 
  - At the password prompt, enter the personal access token.
- How to push container to Dockerhub
  - `docker push eggr0ll/mysite:latest`
- Configure GitHub Secrets
  - what credentials are needed - DockerHub credentials (do not state your credentials)
    - open Docker Hub account settings 
    - go to Security and click on secrets to hide your username and token
  - set secrets and secret names
    - you can refer to them in a YAML file using the .secrets tag and the name of the secret
    - docker hub username (secrets.DOCKER_USERNAME)
    - docker hub token (secrets.DOCKER_TOKEN)
- Behavior GitHub Workflow
  - what does it do and when
    - A workflow is a configurable automated process that will run one or more jobs. 
    - Workflows are defined by a YAML file checked in to your repository and will run when triggered by an event in your repository, or they can be triggered manually, or at a defined schedule.
  - variables to change (repository, etc.)
    - adding the Docker Hub secrets (username and password, and the image name)

```
name: docker-build-push

on: [push]

env:
  DOCKER_REPO: mysite

jobs:
  docker-build-push:
    runs-on: ubuntu-latest
    steps:
      - name: checking out repo
        uses: actions/checkout@v3
      - run: echo "post-checkout" && ls -lah && pwd
      - name: login to docker hub
        uses: docker/login-action@v1
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_TOKEN }}
      - name: docker buildx
        uses: docker/setup-buildx-action@v1
      - name: build and push
        uses: docker/build-push-action@v2
        with:
          push: true
          tags: ${{secrets.DOCKER_USERNAME }}/${{ env.DOCKER_REPO }}:latest
```
  
### Part 3 - Deployment

- Container restart script
  - pull-restart.sh
 ```
 #!/bin/bash

# Pull docker image
# Docker pull eggr0ll/mysite:latest
# Kill old running container (to clear host port)
echo "stopping container"
docker stop eggroll

# Removes old container/images
docker system prune -f -a

# Pull docker container post prune
echo "pulling from repo"
docker pull eggr0ll/mysite:latest

# Run new container
echo "run container eggroll"
docker run -d --name eggroll -p 80:80 eggr0ll/mysite:latest
```
- Webhook task definition file
  - redeploy.json:
```
[
        {
                "id": "redeploy",
                "execute-command": "/home/ubuntu/pull-restart.sh",
                "command-working-directory": "/var/webhook"
        }
]
```
- Setting up a webhook on the server
  - How you created you own listener
    - `/home/ubuntu/go/bin/webhook -hooks /home/ubuntu/redeploy.json -verbose >> /home/ubuntu/logs`
  - How you installed and are running the [webhook on GitHub](https://github.com/adnanh/webhook)
    - First install Go: `sudo snap install go`
    - Extract the files with tar: `sudo tar -C /usr/local -xzf go1.18.1.linux-amd64.tar.gz`
    - Can manually add the PATH to .profile or use `echo "export PATH=$PATH:/usr/local/go/bin">> .profile`
    - Install webhook: `go install github.com/adnanh/webhook@latest`
    - Redirect output to logs.txt: `/home/ubuntu/go/bin/webhook -hooks /home/ubuntu/redeploy.json -verbose >> /home/ubuntu/logs.txt`
- Setting up a notifier in DockerHub
  - Access your repository and select 'Webhooks'
  - It will then prompt you to enter a name then in the black space to the right enter filled with your details
  - http://ipaddress:9000/id?Target=targetToken

### Part 4 - Diagramming
```mermaid
  graph TD;
      A[Install Docker] --> B{Have you installed Docker?};
      B -- No --> C[sudo apt install docker.io];
      B -- Yes --> D[Build container];
      C --> D[Build container];
      D --> E[Run the container];
      E --> F[Paste URL into browser];
      F --> G{Is it running?};
      G -- No -->H[Troubleshoot];
      G -- Yes -->L[You successfully built your container!]
      H --> I[Check that docker is running];
      I -- Yes --> J[Check if your container built successfully: docker ps -a]
      I -- No --> B;
      J -- Yes --> K[Check Google];
      J -- No --> C;
      L --> M[Create Docker Hub repository];
      M --> N[Create a New Access Token];
      N --> O[Make username and password secrets];
      O --> P[Create a .yml file in workflows to login, build, and push to dockerhub];
      P --> Q{Ready for Part 3?};
      Q -- No --> K;
      Q -- Yes --> R[Create a script that restarts the container];
      R --> S[Create hook id/.json file];
      S --> T[Create listener];
      T --> U{Have you installed go/webhooks?};
      U -- No --> V[sudo snap install go];
      V --> W[Export path to .profile];
      W --> X[go install webhook with adnanh];
      U -- Yes --> Y[Run the Webhook];
      X --> Y;
      Y --> Z[Set up notifier in Docker Hub];
      Z --> A2[Paste the link to the webhook in the browser];
      A2 --> B2{Did it work?};
      B2 -- Yes --> C2[You Win!];
      B2 -- No --> D2{Check that you downloaded the correct version of go};
      D2 -- Yes --> E2[Check the server for your public ip];
      D2 -- No --> Z;
      E2 --> F2{Is it displaying your html?};
      F2 -- Yes --> G2[Let your notifier deal with it, you are done];
      F2 -- No --> H2[Check that the server is displaying over your port];
      H2 --> I2{Is it the port open?};
      I2 -- Yes --> K;
      I2 -- No --> J2[open the port];
      J2 --> A2;
```
