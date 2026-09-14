CA65 ?= ca65
LD65 ?= ld65
PYTHON ?= python3
REGION ?= pal

BUILD := build
ASSET_DIR := $(BUILD)/assets
ASSET_STAMP := $(ASSET_DIR)/.room00.stamp
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

.PHONY: all assets clean guard guard-strict check-tools smoke

all: guard check-tools $(ROM)

check-tools:
	@command -v $(CA65) >/dev/null || { echo "ca65 not found; run ./install.sh"; exit 1; }
	@command -v $(LD65) >/dev/null || { echo "ld65 not found; run ./install.sh"; exit 1; }
	@command -v $(PYTHON) >/dev/null || { echo "python3 not found; run ./install.sh"; exit 1; }

guard:
	@$(PYTHON) tools/check_isolation.py

guard-strict:
	@$(PYTHON) tools/check_isolation.py --working-tree

$(BUILD):
	@mkdir -p $(BUILD)

$(ASSET_DIR): | $(BUILD)
	@mkdir -p $(ASSET_DIR)

$(ASSET_STAMP): tools/room00_assets.py | $(ASSET_DIR)
	$(PYTHON) tools/room00_assets.py --out-dir $(ASSET_DIR)
	@touch $@

assets: $(ASSET_STAMP)

$(OBJ): src/main.asm src/hardware.inc src/game_clock.asm src/room00.asm $(ASSET_STAMP) | $(BUILD)
	$(CA65) --cpu 65816 -I src -I $(ASSET_DIR) $(REGION_DEFS) -g -o $@ $<

$(ROM): $(OBJ) lorom.cfg tools/fix_checksum.py tools/test_rom.py
	$(LD65) -C lorom.cfg -m $(MAP) -Ln $(DBG) -o $@ $(OBJ)
	@test "$$(stat -c%s "$@")" -eq 32768 || { echo "unexpected ROM size"; exit 1; }
	$(PYTHON) tools/fix_checksum.py $@
	$(PYTHON) tools/test_rom.py $@
	@echo "Built $(ROM) ($(REGION))"

smoke: $(ROM)
	@$(PYTHON) tools/test_rom.py $(ROM)

clean:
	rm -rf $(BUILD)
