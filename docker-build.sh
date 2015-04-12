#! /bin/bash

echo "===================================="
echo "==== Removing old baha docker image"
echo "===================================="
docker rmi baha

echo "===================================="
echo "==== Building image"
echo "===================================="
docker build -t baha .
