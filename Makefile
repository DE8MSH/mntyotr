PCEAS ?= pceas
NAME := monty
ROM := build/$(NAME).pce
SRC := src/main.asm

# install.sh clones HuC here by default. Override HUC_HOME when needed.
HUC_HOME ?= $(HOME)/.local/opt/huc
PCE_INCLUDE := src:$(HUC_HOME)/examples/asm/elmer/include:$(HUC_HOME)/examples/asm/elmer/font:$(HUC_HOME)/include/hucc
export PCE_INCLUDE

PCEAS_FLAGS := --raw --newproc --strip -gA -m -l 2 -S

.PHONY: all release debug smoke run audit audit-strict check-tools clean
all: release
release: $(ROM)

check-tools:
	@command -v $(PCEAS) >/dev/null || { echo "pceas not found; run ./install.sh"; exit 1; }
	@test -f "$(HUC_HOME)/examples/asm/elmer/include/bare-startup.asm" || { echo "HuC CORE library not found under $(HUC_HOME)"; exit 1; }

# Fast, emulator-free whole-game parity scan. In addition to gameplay truth,
# guard every source-derived late Decor room/x/y/type, dimension and colour stream.
audit:
	@mkdir -p build
	PYTHONPATH=tools python3 tools/test_decor_records_20_33.py
	python3 tools/playthrough_audit_complete.py --json build/playthrough-audit.json --text build/playthrough-audit.txt

# Completion gate: fail not only on wrong data but also on known missing content.
audit-strict:
	@mkdir -p build
	PYTHONPATH=tools python3 tools/test_decor_records_20_33.py
	python3 tools/playthrough_audit_complete.py --strict --json build/playthrough-audit.json --text build/playthrough-audit.txt

$(ROM): $(SRC) src/platform.inc | check-tools
	@mkdir -p build
	@rm -f src/main.pce src/main.sym src/main.lst
	$(PCEAS) $(PCEAS_FLAGS) -o $(ROM) $(SRC)
	@[ ! -f src/main.sym ] || mv src/main.sym build/$(NAME).sym
	@[ ! -f src/main.lst ] || mv src/main.lst build/$(NAME).lst

debug: release
smoke: release
run: release
	./run.sh
clean:
	rm -rf build src/main.pce src/main.sym src/main.lst
