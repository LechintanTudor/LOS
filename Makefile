.POSIX:
.SUFFIXES:

#
# Run
#

RUN_DIR = run
RUN_OVMF_VARS = $(RUN_DIR)/OVMF_VARS.4m.fd
BOOT_DIR = $(RUN_DIR)/boot
BOOT_KERNEL = $(BOOT_DIR)/kernel.elf
BOOT_LIMINE_CONF = $(BOOT_DIR)/limine.conf
EFI_BOOT_DIR = $(BOOT_DIR)/EFI/BOOT
EFI_BOOT_LOADER = $(EFI_BOOT_DIR)/BOOTX64.EFI

RUN_ALL = \
	$(RUN_OVMF_VARS) \
	$(BOOT_KERNEL) \
	$(BOOT_LIMINE_CONF) \
	$(EFI_BOOT_LOADER)

#
# Build
#

BUILD_DIR = build
BUILD_ASM_OBJ = $(BUILD_DIR)/asm.o
BUILD_KERNEL_OBJ = $(BUILD_DIR)/kernel.o
BUILD_KERNEL = $(BUILD_DIR)/kernel.elf

ODIN_CHECK_FLAGS = \
	-collection:extern=extern \
	-target:freestanding_amd64_sysv \
	-no-entry-point \
	-no-thread-local

ODIN_BUILD_FLAGS = \
	$(ODIN_CHECK_FLAGS) \
	-build-mode:obj \
	-use-single-module \
	-no-crt

#
# Source
#

ASM_SRC = src_asm/cpu.S

ODIN_SRC = \
	src_odin/boot.odin \
	src_odin/cpu.odin \
	src_odin/logger.odin \
	src_odin/main.odin \
	src_odin/page.odin

#
# Phony
#

.PHONY: all run check fmt clean

all: $(RUN_ALL)

run: all
	qemu-system-x86_64 \
		-drive if=pflash,format=raw,readonly=on,file=ovmf/OVMF_CODE.4m.fd \
		-drive if=pflash,format=raw,file="$(RUN_OVMF_VARS)" \
		-drive format=raw,file=fat:rw:"$(BOOT_DIR)" \
		-debugcon stdio

check:
	odin check src_odin -vet $(ODIN_CHECK_FLAGS)

fmt:
	odinfmt -w src_odin

clean:
	rm -rf "$(BUILD_DIR)" "$(RUN_DIR)"

#
# Run
#

$(RUN_OVMF_VARS): ovmf/OVMF_VARS.4m.fd
	mkdir -p "$(RUN_DIR)"
	cp "$<" "$@"

$(BOOT_KERNEL): $(BUILD_KERNEL)
	mkdir -p "$(BOOT_DIR)"
	cp "$<" "$@"

$(BOOT_LIMINE_CONF): config/limine.conf
	mkdir -p "$(BOOT_DIR)"
	cp "$<" "$@"

$(EFI_BOOT_LOADER): extern/limine/bin/BOOTX64.EFI
	mkdir -p "$(EFI_BOOT_DIR)"
	cp "$<" "$@"

#
# Build
#

$(BUILD_ASM_OBJ): $(ASM_SRC)
	mkdir -p "$(BUILD_DIR)"
	as -o "$@" $(ASM_SRC)

$(BUILD_KERNEL_OBJ): $(ODIN_SRC)
	mkdir -p "$(BUILD_DIR)"
	odin build src_odin -out:"$@" $(ODIN_BUILD_FLAGS)

	# Temporary fix for Odin compiler bug.
	mv build/kernel.obj build/kernel.o

$(BUILD_KERNEL): $(BUILD_KERNEL_OBJ) $(BUILD_ASM_OBJ) config/link.ld
	ld $(BUILD_KERNEL_OBJ) $(BUILD_ASM_OBJ) \
	    -o "$@" \
	    -nostdlib \
	    -static \
	    -T config/link.ld
