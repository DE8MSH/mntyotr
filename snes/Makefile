CA65 ?= ca65
LD65 ?= ld65
PYTHON ?= python3
REGION ?= pal

BUILD := build
OBJ := $(BUILD)/main.o
ROM := $(BUILD)/monty.sfc
MAP := $(BUILD)/monty.map
DBG := $(BUILD)/monty.lbl

ifeq ($(REGION),pal)
REGION_DEFS := -D SNES_PAL=1
else ifeq ($(REGION),ntsc)
REGION_DEFS := -D SNES_NTSC=1
else
$(error REGION must be pal or ntsc)
endif

.PHONY: all clean guard guard-strict check-tools

all: guard check-tools $(ROM)

check-tools:
	@command -v $(CA65) >/dev/null || { echo "ca65 not found (install cc65)"; exit 1; }
	@command -v $(LD65) >/dev/null || { echo "ld65 not found (install cc65)"; exit 1; }

guard:
	@$(PYTHON) tools/check_isolation.py

guard-strict:
	@$(PYTHON) tools/check_isolation.py --working-tree

$(BUILD):
	@mkdir -p $(BUILD)

$(OBJ): src/main.asm src/hardware.inc src/game_clock.asm | $(BUILD)
	$(CA65) --cpu 65816 -I src $(REGION_DEFS) -g -o $@ $<

$(ROM): $(OBJ) lorom.cfg
	$(LD65) -C lorom.cfg -m $(MAP) -Ln $(DBG) -o $@ $(OBJ)
	@test "$$(stat -c%s "$@")" -eq 32768 || { echo "unexpected ROM size"; exit 1; }
	@echo "Built $(ROM) ($(REGION))"

clean:
	rm -rf $(BUILD)
