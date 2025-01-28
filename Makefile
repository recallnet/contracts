.PHONY: actor-facade

actor-facade:
	forge build
	cd crates/facade && BUILD_BINDINGS=1 cargo build
