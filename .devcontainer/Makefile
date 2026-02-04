TAG=kape1395/tlaplus_devcontainer

all: build

build:
	docker build . -t $(TAG)

run: build
	docker run --rm -it $(TAG)

.PHONY: all build run
