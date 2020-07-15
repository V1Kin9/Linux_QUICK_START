ifneq ("$(wildcard .config)","")
	include .config
endif

# Configuration #
preconfig:
ifeq ("$(wildcard .config)","")
	$(error "Please run make menuconfig first.")
endif

menuconfig:
	@mkdir -p build
	@rsync -ur host-tools/menuconfig build
	@make -C build/menuconfig
	@./build/menuconfig/mconf Config.in

list-defconfigs:
	@echo 'Built-in configs:'
	@$(foreach b, $(sort $(notdir $(wildcard defconfig/*_defconfig))), \
	  printf "  %-35s - Build for %s\\n" $(b) $(b:_defconfig=);)
	@echo

%_defconfig:
	@./build/menuconfig/conf --defconfig=defconfig/$@ Config.in


# Target #
ifdef CONFIG_WH64
  target = wh64
else
  target = wh32
endif



# Toolchain #
ifdef CONFIG_WH64
  CROSS_COMPILE	= riscv64-unknown-linux-gnu-
else
  CROSS_COMPILE = riscv32-unknown-linux-gnu-
endif

AS              = $(CROSS_COMPILE)as
LD              = $(CROSS_COMPILE)ld
CC              = $(CROSS_COMPILE)gcc
CPP             = $(CC) -E
AR              = $(CROSS_COMPILE)ar
NM              = $(CROSS_COMPILE)nm
STRIP           = $(CROSS_COMPILE)strip
OBJCOPY         = $(CROSS_COMPILE)objcopy
OBJDUMP         = $(CROSS_COMPILE)objdump

export CROSS_COMPILE

# rsync the src #
sync:
	@mkdir -p build
	-cp -f host-tools/mk_rootfs.sh build/
	@cd build && ./mk_rootfs.sh
	@rsync -ur src/busybox build
	cp -f defconfig/busybox/busybox_defconfig build/busybox/.config
	@rsync -a src/linux build
	@cp defconfig/linux/$(target)-defconfig build/linux/arch/riscv/configs/defconfig
	@make -C build/linux ARCH=riscv defconfig
	@rsync -ur src/opensbi build
	@rsync -ur defconfig/dts build


# rootfs #
rootfs: 
	@echo '################## Building the rootfs ##################'
	@make -C build/busybox 
	@make -C build/busybox install


# Linux Kernel #
kernel:
	@echo '################## Building the kernel ##################'
	@make -C build/linux -j4 
	$(OBJCOPY) -O binary build/linux/vmlinux build/linux/vmlinux.bin


# dtb #
dtb:
	@echo '################## Compiling the dts ##################'
	-cp build/linux/scripts/dtc/dtc build/dts
	-cp host-tools/dts2dtb.sh build/dts
	cd build/dts/ && ./dts2dtb.sh $(target)


# RISC-V opensbi #
opensbi:
	@echo '################## Building the opensbi ##################'
	@make -C build/opensbi PLATFORM=uctechip/$(target) FW_PAYLOAD_PATH=$(CURDIR)/build/linux/vmlinux.bin FW_PAYLOAD_FDT_PATH=$(CURDIR)/build/dts/$(target).dtb


Image:	rootfs kernel dtb opensbi
	@mkdir -p build/output
	-cp build/opensbi/build/platform/uctechip/$(target)/firmware/fw_payload.elf build/output/Image


all: sync Image

# CLEAN #
clean: 	
	@make -C build/busybox clean
	@make -C build/linux clean
	@make -C build/opensbi clean
	@rm -f build/dts/$(target).dtb
	@rm -f build/output/Image

distclean:
	@rm -rf build





