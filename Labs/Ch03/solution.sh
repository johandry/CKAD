#!/bin/bash

echo "Solutions to Chapter 3 Labs"

docker_build_n_run() {
  echo "Docker build image:"
  cat <<EOD | docker build -t simpleapp -f - .
FROM python:2
ADD simple.py /
CMD [ "python", "./simple.py" ]
EOD

  echo "Docker images:"
  docker images simpleapp

  echo "Docker run:"
  docker run -rm simpleapp
}

docker_build_n_run