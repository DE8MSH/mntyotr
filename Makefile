PCEAS ?= pceas
ROM := build/monty.pce
SRC := src/main.asm

.PHONY: all release debug smoke run clean
all: release
release: $(ROM)

$(ROM): $(SRC)
	@mkdir -p build
	$(PCEAS) -raw $(SRC) $(ROM)

debug: release
smoke: release
run: release
	./run.sh
clean:
	rm -rf build
