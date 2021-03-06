#!/bin/bash

# This script has only been tested on Trusty ...

function usage {
    echo
    echo "Usage: sudo ./docker-course.sh [OPTIONS]"
    echo
    echo "    -h        this help"
    echo "    -s        takes an integer, indicates that we should stop at this section"
    echo "    -r        replay, runs all the commands without user input"
    echo "    -i        interactive replay, requires keypresses to run commands"
    echo
    exit 1
}

if [[ $EUID -ne 0 ]]; then
    usage;
fi

# shellcheck disable=SC1090
source "${HOME}/.bashrc.training"

if [[ -z ${DOCKER_TRAINING_AUTHOR+x} || -z ${DOCKER_TRAINING_EMAIL+x} || -z ${DOCKER_TRAINING_USER+x} || -z ${DOCKER_TRAINING_EDITOR+x} ]];
then
    echo "Please run 'source ./user-setup.sh' first";
    exit;
fi

INTERACTIVE=0
BREAK=0
LIST=1 # default mode

while getopts 'hirs:' flag; do
    case "${flag}" in
        h) usage ;;
        i) INTERACTIVE=1 ;;
        r) LIST=0 ;;
        s) BREAK="${OPTARG}" ;;
        *) error "Unexpected option ${flag}" ;;
    esac
done

function wait_for_keypress {
    if [[ $INTERACTIVE == '1' ]];
    then
        read -n1 -rsp "" key
        if [[ $key == 'q' ]]; then
            echo
            echo "exiting (q for exit)"
            exit;
        fi
    fi
    echo
}

if [[ ! $LIST == '1' ]];
then
    echo "# Cleaning up old containers before we start:"
    # check that these containers don't exist
    for container in insane_babbage nostalgic_morse dbdata2 dbdata db1 db2 db3 web1 web2 web3 web db;
    do
        # stop any running containers
        if docker ps | grep -q " $container "
        then
            docker stop $container
        fi

        # remove containers
        if docker ps -a | grep -q " $container "
        then
            docker rm $container
        fi
    done
    echo "Cleaning up images before we start:"
    docker images | tail -n +2 | while read -r line
    do
        IMAGE_ID=$( echo "$line" | awk '{ print $3 }' )
        if echo "$line" | grep -q '<none>'
        then
            docker rmi "$IMAGE_ID"
        fi
    done
fi

# https://docs.docker.com/userguide/dockerizing/
echo "+-----------------------------------------------------------------------------------------------------------------+"
echo "|                              1: https://docs.docker.com/userguide/dockerizing/                                  |"
echo "+-----------------------------------------------------------------------------------------------------------------+"

# Hello world
echo
echo --------------------------------1.01: Hello world------------------------------------------------------------------

echo -n "$ sudo docker run ubuntu:14.04 /bin/echo 'Hello world'"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker run ubuntu:14.04 /bin/echo 'Hello world'
fi

# An interactive container
# -i, --interactive=false    Keep STDIN open even if not attached
# -t, --tty=false            Allocate a pseudo-TTY
echo
echo --------------------------------1.02: An interactive container-----------------------------------------------------

echo "# try this command: 'cat /etc/os-release' inside the container"
echo "# type exit when you are done looking around"
echo -n "$ sudo docker run -t -i ubuntu:14.04 /bin/bash"
wait_for_keypress;
if [[ $INTERACTIVE == '1' ]];
then
    docker run -t -i ubuntu:14.04 /bin/bash
fi

# A daemonized Hello world
echo
echo --------------------------------1.03: A daemonized Hello world-----------------------------------------------------

echo -n '$ sudo docker run --name=insane_babbage -d ubuntu:14.04 /bin/sh -c "while true; do echo hello world; sleep 1; done"'
wait_for_keypress;

# Note the use of --name=insane_babbage which gives us a consistent name
# TODO: check we are not already running insane_babbage before running this
if [[ ! $LIST == '1' ]];
then
    docker run --name=insane_babbage -d ubuntu:14.04 /bin/sh -c "while true; do echo hello world; sleep 1; done"
fi

echo -n '$ sudo docker ps'
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker ps
fi

echo -n '$ sudo docker logs insane_babbage'
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker logs insane_babbage | tail -n 10
fi

echo -n '$ sudo docker stop insane_babbage'
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker stop insane_babbage
fi

echo -n '$ sudo docker ps'
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker ps
fi

if [[ $BREAK == '1' ]];
then
    exit;
fi

# https://docs.docker.com/userguide/usingdocker/
echo
echo "+-----------------------------------------------------------------------------------------------------------------+"
echo "|                              2: https://docs.docker.com/userguide/usingdocker/                                  |"
echo "+-----------------------------------------------------------------------------------------------------------------+"

# Working with containers
echo
echo --------------------------------2.01: Working with containers------------------------------------------------------

echo -n "$ sudo docker version"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker version
fi

# Get Docker command help
echo
echo --------------------------------2.02: Get Docker command help------------------------------------------------------

echo -n "$ docker --help"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker --help
fi
echo -n "$ sudo docker attach --help"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker attach --help
fi

# Running a web application in Docker
echo
echo --------------------------------2.03: Running a web application in Docker------------------------------------------

echo "# Note the use of --name=nostalgic_morse which gives us a consistent name"
echo "# -P, --publish-all=false    Publish all exposed ports to random ports"
echo -n '$ sudo docker run --name=nostalgic_morse -d -P training/webapp python app.py'
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker run --name=nostalgic_morse -d -P training/webapp python app.py
fi

# Viewing our web application container
echo
echo --------------------------------2.04: Viewing our web application container----------------------------------------

echo -n '$ sudo docker ps -l'
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker ps -l
fi

# A network port shortcut
echo
echo --------------------------------2.05: A network port shortcut------------------------------------------------------

echo -n "$ sudo docker port nostalgic_morse 5000"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker port nostalgic_morse 5000
fi

# 0.0.0.0, in this context, means "all IPv4 addresses on the local machine"
# Lets take a closer look:
echo -n "$ curl -s -i http://\$( sudo docker port nostalgic_morse 5000 )/"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    curl -s -i http://"$( docker port nostalgic_morse 5000 )"/
fi
echo

echo -n "$ sudo lsof -i | egrep 'docker|COMMAND'"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    lsof -i | egrep 'docker|COMMAND'
fi

# Viewing the web application’s logs
echo
echo --------------------------------2.06: Viewing the web application’s logs-------------------------------------------

echo "# hit CTRL-C to exit"
echo -n "$ sudo docker logs -f nostalgic_morse"
wait_for_keypress;
if [[ $INTERACTIVE == '1' ]];
then
    docker logs -f nostalgic_morse
    echo
fi

# Looking at our web application container’s processes
echo
echo --------------------------------2.07: Looking at our web application container’s processes-------------------------

echo -n "$ sudo docker top nostalgic_morse"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker top nostalgic_morse
fi

# Inspecting our web application container
echo
echo --------------------------------2.08: Inspecting our web application container-------------------------------------

echo -n "$ sudo docker inspect nostalgic_morse"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker inspect nostalgic_morse
fi

echo -n "$ sudo docker inspect -f '{{ .NetworkSettings.IPAddress }}' nostalgic_morse"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker inspect -f '{{ .NetworkSettings.IPAddress }}' nostalgic_morse
fi

# Stopping our web application container
echo
echo --------------------------------2.09: Stopping our web application container---------------------------------------

echo -n "$ sudo docker stop nostalgic_morse"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker stop nostalgic_morse
fi

echo -n "$ sudo docker ps -l"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker ps -l
fi

# Restarting our web application container
echo
echo --------------------------------2.10: Restarting our web application container-------------------------------------

echo -n "$ sudo docker start nostalgic_morse"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker start nostalgic_morse
fi

echo -n "$ sudo docker ps -l"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker ps -l
fi

# also 'sudo docker restart nostalgic_morse'

# Removing our web application container
echo
echo --------------------------------2.11: Removing our web application container---------------------------------------

echo "# we expect this command to fail as the container is still running"
echo -n "$ sudo docker rm nostalgic_morse"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker rm nostalgic_morse
fi

echo -n "$ sudo docker stop nostalgic_morse"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker stop nostalgic_morse
fi

echo -n "$ sudo docker rm nostalgic_morse"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker rm nostalgic_morse
fi

if [[ $BREAK == '2' ]];
then
    exit;
fi

# https://docs.docker.com/userguide/dockerimages/
echo
echo "+-----------------------------------------------------------------------------------------------------------------+"
echo "|                              3: https://docs.docker.com/userguide/dockerimages/                                 |"
echo "+-----------------------------------------------------------------------------------------------------------------+"

# Listing images on the host
echo
echo --------------------------------3.01: Listing images on the host---------------------------------------------------

echo -n '$ sudo docker images'
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker images
fi

# Getting a new image
echo
echo --------------------------------3.02: Getting a new image----------------------------------------------------------

echo -n '$ sudo docker pull centos'
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker pull centos
fi

echo "# type exit when you are done looking around"
echo "# try this command: 'cat /etc/os-release'"
echo -n '$ sudo docker run -t -i centos /bin/bash'
wait_for_keypress;
if [[ $INTERACTIVE == '1' ]];
then
    docker run -t -i centos /bin/bash
fi

# Finding images
echo
echo --------------------------------3.03: Finding images---------------------------------------------------------------

echo -n '$ sudo docker search sinatra'
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker search sinatra
fi

# Pulling our image
echo
echo --------------------------------3.04: Pulling our image------------------------------------------------------------

echo -n '$ sudo docker pull training/sinatra'
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker pull training/sinatra
fi

echo "# type exit when you are done looking around"
echo -n '$ sudo docker run -t -i training/sinatra /bin/bash'
wait_for_keypress;
if [[ $INTERACTIVE == '1' ]];
then
    docker run -t -i training/sinatra /bin/bash
fi

# Creating our own images
echo
echo --------------------------------3.05: Creating our own images------------------------------------------------------

echo "# type 'gem install json' inside your container"
echo "# type exit when you are done"
echo -n '$ sudo docker run -t -i training/sinatra /bin/bash'
wait_for_keypress;
if [[ $INTERACTIVE == '1' ]];
then
    docker run -t -i training/sinatra /bin/bash
else
    if [[ ! $LIST == '1' ]];
    then
        docker run training/sinatra gem install json
    fi
fi

CONTAINER_ID=$(docker ps -l -q)

echo -n "$ sudo docker commit -m 'Added json gem' -a \"$DOCKER_TRAINING_AUTHOR\" $CONTAINER_ID $DOCKER_TRAINING_USER/sinatra:v1"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker commit -m "Added json gem" -a "$DOCKER_TRAINING_AUTHOR" "$CONTAINER_ID" "$DOCKER_TRAINING_USER/sinatra:v1"
fi

echo -n '$ sudo docker images'
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker images
fi

echo "# type exit when you are done"
echo -n "$ sudo docker run -t -i $DOCKER_TRAINING_USER/sinatra:v1 /bin/bash"
wait_for_keypress;
if [[ $INTERACTIVE == '1' ]];
then
    docker run -t -i "$DOCKER_TRAINING_USER/sinatra:v1" /bin/bash
fi

# Building an image from a Dockerfile
echo
echo --------------------------------3.06: Building an image from a Dockerfile------------------------------------------

DIRECTORY=$(pwd)/sinatra
DOCKERFILE="$DIRECTORY/Dockerfile"
echo -n "$ mkdir $DIRECTORY"
wait_for_keypress;
if [ ! -d "$DIRECTORY" ]; then
    mkdir sinatra
fi
echo -n "$ cd $DIRECTORY"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    cd "$DIRECTORY" || exit
fi
echo -n "$ touch $DOCKERFILE"
wait_for_keypress;

if [[ ! $LIST == '1' ]];
then
    if [ -f "$DOCKERFILE" ]
    then
        rm "$DOCKERFILE"
    else
        touch "$DOCKERFILE"
    fi
fi

if [[ $INTERACTIVE == '1' ]];
then
    $DOCKER_TRAINING_EDITOR Dockerfile
else
    if [[ ! $LIST == '1' ]];
    then
        echo "# This is a comment
FROM ubuntu:14.04
MAINTAINER $DOCKER_TRAINING_AUTHOR <$DOCKER_TRAINING_EMAIL>
RUN apt-get update && apt-get install -y ruby ruby-dev
RUN gem install sinatra
" > Dockerfile
    fi
fi

echo -n "$ cat Dockerfile"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    cat Dockerfile
fi

echo -n "$ sudo docker build -t $DOCKER_TRAINING_USER/sinatra:v2 ."
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker build -t "$DOCKER_TRAINING_USER/sinatra:v2" .
fi

# Setting tags on an image
echo
echo --------------------------------3.07: Setting tags on an image-----------------------------------------------------

IMAGE_ID=$( docker images "$DOCKER_TRAINING_USER/sinatra"  | grep v2 | awk '{print $3}' )
echo -n "$ sudo docker tag $IMAGE_ID $DOCKER_TRAINING_USER/sinatra:devel"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    if ! docker images | awk '{ print $1 $2 }' | grep -q "$DOCKER_TRAINING_USER/sinatradevel";
    then
        docker tag "$IMAGE_ID" "$DOCKER_TRAINING_USER/sinatra:devel"
    fi
fi

echo -n "$ sudo docker images $DOCKER_TRAINING_USER/sinatra"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker images "$DOCKER_TRAINING_USER/sinatra"
fi

# Image Digests
echo
echo --------------------------------3.08: Image Digests----------------------------------------------------------------

echo -n "$ sudo docker images --digests | head"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker images --digests | head
fi

# Push an image to Docker Hub
echo
echo --------------------------------3.09: Push an image to Docker Hub--------------------------------------------------
# TODO: use local registry here

# Remove an image from the host
# TODO: remove containers that are using this image first
echo --------------------------------3.10: Remove an image from the host------------------------------------------------

echo -n "$ sudo docker rmi training/sinatra"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker rmi training/sinatra
fi

if [[ $BREAK == '3' ]];
then
    exit;
fi

# https://docs.docker.com/userguide/dockerlinks/
echo
echo "+-----------------------------------------------------------------------------------------------------------------+"
echo "|                              4: https://docs.docker.com/userguide/dockerlinks/                                  |"
echo "+-----------------------------------------------------------------------------------------------------------------+"

# TODO: should we run any of the commands in:
# Connect using network port mapping

# The importance of naming
echo
echo --------------------------------4.01: The importance of naming-----------------------------------------------------

echo -n "$ sudo docker run -d -P --name web training/webapp python app.py"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker run -d -P --name web training/webapp python app.py
fi

echo -n "$ sudo docker ps -l"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker ps -l
fi

# Communication across links
echo
echo --------------------------------4.02: Communication across links---------------------------------------------------

echo -n "$ sudo docker run -d --name db training/postgres"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker run -d --name db training/postgres
fi

echo -n "$ sudo docker rm -f web"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker rm -f web
fi

echo -n "$ sudo docker run -d -P --name web --link db:db training/webapp python app.py"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker run -d -P --name web --link db:db training/webapp python app.py
fi

echo -n "$ sudo docker inspect -f \"{{ .HostConfig.Links }}\" web"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker inspect -f "{{ .HostConfig.Links }}" web
fi

echo -n "$ sudo docker run --rm --name web2 --link db:db training/webapp env"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker run --rm --name web2 --link db:db training/webapp env
fi

# Updating the /etc/hosts file
echo
echo --------------------------------4.03: Updating the /etc/hosts file-------------------------------------------------

echo "# type 'cat /etc/hosts'"
echo "# type 'apt-get install -yqq inetutils-ping'"
echo "# type 'ping webdb'"
echo "# type 'nc -v -z webdb 5432'"
echo "# type exit when you are done running these commands"
echo -n "$ sudo docker run -t -i --rm --link db:webdb training/webapp /bin/bash"
wait_for_keypress;
if [[ $INTERACTIVE == '1' ]];
then
    docker run -t -i --rm --link db:webdb training/webapp /bin/bash
else
    if [[ ! $LIST == '1' ]];
    then
        docker run --rm --link db:webdb training/webapp cat /etc/hosts
    fi
fi

echo -n "$ sudo docker restart db"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker restart db
fi

echo "# type 'cat /etc/hosts'"
echo "# type exit when you are done"
echo "$ sudo docker run -t -i --rm --link db:db training/webapp /bin/bash"
wait_for_keypress;
if [[ $INTERACTIVE == '1' ]];
then
    docker run -t -i --rm --link db:db training/webapp /bin/bash
else
    if [[ ! $LIST == '1' ]];
    then
        docker run --rm --link db:db training/webapp cat /etc/hosts
    fi
fi

if [[ $BREAK == '4' ]];
then
    exit;
fi

# https://docs.docker.com/userguide/dockervolumes/
echo
echo "+-----------------------------------------------------------------------------------------------------------------+"
echo "|                              5: https://docs.docker.com/userguide/dockervolumes/                                |"
echo "+-----------------------------------------------------------------------------------------------------------------+"

# Adding a data volume
echo
echo --------------------------------5.01: Adding a data volume---------------------------------------------------------

if [[ ! $LIST == '1' ]];
then
    docker rename web web1
fi

echo -n "$ sudo docker run -d -P --name web -v /webapp training/webapp python app.py"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker run -d -P --name web -v /webapp training/webapp python app.py
fi

# Locating a volume
echo
echo --------------------------------5.02: Locating a volume------------------------------------------------------------

echo -n "$ sudo docker inspect web"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker inspect web
fi

# Mount a host directory as a data volume
echo
echo --------------------------------5.03: Mount a host directory as a data volume--------------------------------------

if [[ ! $LIST == '1' ]];
then
    docker rename web web2
fi

echo -n "$ sudo docker run -d -P --name web -v /src/webapp:/opt/webapp training/webapp python app.py"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker run -d -P --name web -v /src/webapp:/opt/webapp training/webapp python app.py
fi

if [[ ! $LIST == '1' ]];
then
    docker rename web web3
fi

echo -n "$ sudo docker run -d -P --name web -v /src/webapp:/opt/webapp:ro training/webapp python app.py"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker run -d -P --name web -v /src/webapp:/opt/webapp:ro training/webapp python app.py
fi

# Mount a host file as a data volume
echo
echo --------------------------------5.04: Mount a host file as a data volume-------------------------------------------

# note correction
echo -n "$ sudo docker run --rm -it -v ~/.bash_history:/root/.bash_history ubuntu /bin/bash"
wait_for_keypress;
if [[ $INTERACTIVE == '1' ]];
then
    docker run --rm -it -v ~/.bash_history:/root/.bash_history ubuntu /bin/bash
fi

# Creating and mounting a data volume container
echo
echo --------------------------------5.05: Creating and mounting a data volume container--------------------------------

echo -n "$ sudo docker create -v /dbdata --name dbdata training/postgres /bin/true"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker create -v /dbdata --name dbdata training/postgres /bin/true
fi

echo -n "$ sudo docker run -d --volumes-from dbdata --name db1 training/postgres"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker run -d --volumes-from dbdata --name db1 training/postgres
fi

echo -n "$ sudo docker run -d --volumes-from dbdata --name db2 training/postgres"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker run -d --volumes-from dbdata --name db2 training/postgres
fi

echo -n "$ sudo docker run -d --name db3 --volumes-from db1 training/postgres"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker run -d --name db3 --volumes-from db1 training/postgres
fi

# Backup, restore, or migrate data volumes
echo
echo --------------------------------5.06: Backup, restore, or migrate data volumes-------------------------------------

echo -n "$ sudo docker run --volumes-from dbdata -v \"$(pwd)\":/backup ubuntu tar cvf /backup/backup.tar /dbdata"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker run --volumes-from dbdata -v "$(pwd)":/backup ubuntu tar cvf /backup/backup.tar /dbdata
fi

echo -n "$ sudo docker run -v /dbdata --name dbdata2 ubuntu /bin/bash"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker run -v /dbdata --name dbdata2 ubuntu /bin/bash
    # why no shell here?
fi

echo -n "$ sudo docker run --volumes-from dbdata2 -v \"$(pwd)\":/backup ubuntu cd /dbdata && tar xvf /backup/backup.tar"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker run --volumes-from dbdata2 -v "$(pwd)":/backup ubuntu cd /dbdata && tar xvf /backup/backup.tar
fi

if [[ $BREAK == '5' ]];
then
    exit;
fi

# https://docs.docker.com/userguide/dockerrepos/
echo
echo "+-----------------------------------------------------------------------------------------------------------------+"
echo "|                              6: https://docs.docker.com/userguide/dockerrepos/                                  |"
echo "+-----------------------------------------------------------------------------------------------------------------+"

# Searching for images
echo
echo --------------------------------6.01: Searching for images---------------------------------------------------------

echo -n "$ sudo docker search centos"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker search centos
fi

if [[ $BREAK == '6' ]];
then
    exit;
fi

# Other stuff
echo
echo "+-----------------------------------------------------------------------------------------------------------------+"
echo "|                              7: Diffing                                                                         |"
echo "+-----------------------------------------------------------------------------------------------------------------+"

# Diffing images
echo
echo --------------------------------7.01: Diffing images---------------------------------------------------------------

echo "# type 'echo flubber > test.txt'"
echo "# type exit when done"
echo -n "$ sudo docker run --name=sleepy_cori -it ubuntu:latest /bin/bash"
wait_for_keypress;
if [[ $INTERACTIVE == '1' ]];
then
    docker run --name=sleepy_cori -it ubuntu:latest /bin/bash
else
    if [[ ! $LIST == '1' ]];
    then
        docker run --name=sleepy_cori -it ubuntu:latest echo flubber > test.txt
    fi
fi

echo -n "$ sudo docker ps -a"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker ps -a
fi

echo -n "$ sudo docker restart sleepy_cori"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker restart sleepy_cori
fi

echo -n "$ sudo docker ps"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker ps
fi

echo "# type 'apt-get install mtr-tiny' in the container"
echo "# type exit when done"
echo -n "$ sudo docker attach sleepy_cori"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker attach sleepy_cori
fi

echo -n "$ sudo docker diff sleepy_cori"
wait_for_keypress;
if [[ ! $LIST == '1' ]];
then
    docker diff sleepy_cori
fi

# Potential new sections:
# dockviz
# Docker compose
# https://docs.docker.com/compose/
# Kubernetes / compose demo from http://radar.oreilly.com/2015/07/set-up-kubernetes-with-a-docker-compose-one-liner.html

if [[ $BREAK == '7' ]];
then
    exit;
fi
