.PHONY: test lint

test:
	bats tests/

lint:
	shellcheck -S warning src/*.sh tests/*.bats
