#! /bin/bash

echo "===================================="
echo "==== Removing old baha docker image"
echo "===================================="
docker rmi justenwalker/baha

echo "===================================="
echo "==== Building image"
echo "===================================="
docker build -t justenwalker/baha .
