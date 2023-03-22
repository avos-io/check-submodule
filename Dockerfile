# Container image that runs your code
FROM alpine:latest

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY check-submodule.sh /check-submodule.sh
COPY random-dolphin-fact.sh /random-dolphin-fact.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/check-submodule.sh"]
