.PHONY: test lint

test:
	bats tests/

lint:
	shellcheck src/*.sh tests/*.bats
