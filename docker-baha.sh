#! /bin/bash
BAHA_IMAGE=${BAHA_IMAGE:-"justenwalker/baha"}
BAHA_MOUNT=${BAHA_MOUNT:-$PWD}
BAHA_WORKSPACE_MOUNT=${BAHA_WORKSPACE_MOUNT:-"$BAHA_MOUNT/workspace"}
DOCKER_SOCKET=${DOCKER_SOCK:-"/var/run/docker.sock"}

docker run --rm \
  -v $BAHA_MOUNT:/baha \
  -v $BAHA_WORKSPACE_MOUNT:/workspace \
  -v $DOCKER_SOCKET:/var/run/docker.sock \
  -e BAHA_MOUNT=$BAHA_MOUNT \
  -e BAHA_WORKSPACE_MOUNT=$BAHA_WORKSPACE_MOUNT \
  -e DOCKER_HOST=unix:///var/run/docker.sock \
  $BAHA_IMAGE "$@"
