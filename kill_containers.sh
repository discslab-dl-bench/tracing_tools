#!/bin/bash

containers=$(docker ps | awk '{print $1}' | grep -wv CONTAINER)
for container in $containers;
do
    docker kill $container
    docker rm $container
done