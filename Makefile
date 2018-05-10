#
# (C) 2018 Gunnar Andersson <gand AT acm.org>
# This file is part of casync-docker
#
# N.B . casync-docker is by not an "official" project and is not part of
# casync or systemd.
#
# ---------------------------------------------------------------------
#  USER SETTINGS
#  These normally don't need changing

IMAGE_NAME ?= my_casync
CONTAINER_NAME ?= casync_temp_container
CONTAINER_HOSTNAME ?= casync_worker

# ---------------------------------------------------------------------
# Variables
#
# These are intended to be overridden by defining them in the environment
# before "make run"
#
# WORK_DIR = Work/source dir, mounted at /workdir
# For simple jobs you might use this one only
#
# OUTPUT_DIR, INPUT_DIR = optional mounts if you want to access data
# or write in another location on your host.
# These are mounted at /outputdir and /inputdir respectively.
#
# (In theory INPUT_DIR seems a bit superfluous since you could often just
# use WORK_DIR instead, but it might be clearer this way.  Also when
# supplying seeding directories, you might need to supply another location)
# 
# NOTE: ALL of them default to your current working directory if not specified
#       in environment
WORK_DIR ?= ${PWD}
INPUT_DIR ?= ${PWD}
OUTPUT_DIR ?= ${PWD}

currentuser := $(shell id -u)
currentgroup := $(shell id -g)

default:
	@echo 'Usage: make [build|run (define $$CASYNC_ARGS first)|clean|logs|shell|stop|kill]'
	@echo "Note that this is an ephemeral container (should disappear after command has run) so shell/stop/kill are only for troubleshooting"

build:
	docker build --tag=${IMAGE_NAME} .

run:
	docker run -u ${currentuser}:${currentgroup}    \
            -h "${CONTAINER_HOSTNAME}" --rm -i          \
            -v "${WORK_DIR}:/workdir"                   \
            -v "${INPUT_DIR}:/inputdir"                 \
            -v "${OUTPUT_DIR}:/outputdir"               \
            --name=${CONTAINER_NAME} ${IMAGE_NAME}      \
            ${CASYNC_ARGS}

logs:
	docker logs -f ${CONTAINER_NAME}

shell:
	docker exec -it ${CONTAINER_NAME} /bin/bash

clean:
	@echo "docker rm -v ${CONTAINER_NAME}"
	@docker rm -v ${CONTAINER_NAME} >/dev/null || echo "Container removed already"
	@echo docker rmi ${IMAGE_NAME}:latest 
	@docker rmi ${IMAGE_NAME}:latest 2>/dev/null || echo "Image removed already"

stop:
	docker stop ${CONTAINER_NAME}

kill:
	docker kill ${CONTAINER_NAME}
	docker rm ${CONTAINER_NAME}

