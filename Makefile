ifneq ("$(wildcard .config)","")
	include .config
endif

# Preconfig as a rule to check if current directory includes the .config
PHONY := preconfig
preconfig:

ifeq ("$(wildcard .config)","")
	$(error "Please run make menuconfig first.")
endif

# Menu of configuration
PHONY += menuconfig
menuconfig:

	@mkdir -p build
	@rsync -ur host-tools/menuconfig build
	@make -C build/menuconfig
	@./build/menuconfig/mconf Config.in

# List the defconfigs of WH processors
PHONY += list-defconfigs
list-defconfigs:
	@echo 'Built-in configs:'
	@$(foreach b, $(sort $(notdir $(wildcard defconfig/*_defconfig))), \
	  printf "  %-35s - Build for %s\\n" $(b) $(b:_defconfig=);)
	@echo

# Set the configuration for the target
PHONY += %_defconfig
%_defconfig:
	@./build/menuconfig/conf --defconfig=defconfig/$@ Config.in

# Target architeture
ifdef CONFIG_WH64
  target = wh64
else
  target = wh32
endif

# Toolchain 
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

# rsync the src 
PHONY += sync
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


# rootfs 
PHONY += rootfs
rootfs: 
	@echo '################## Building the rootfs ##################'
	@make -C build/busybox 
	@make -C build/busybox install


# Linux Kernel
PHONY += kernel
kernel:
	@echo '################## Building the kernel ##################'
	@make -C build/linux -j4 
	$(OBJCOPY) -O binary build/linux/vmlinux build/linux/vmlinux.bin


# dtb
PHONY += dtb
dtb:
	@echo '################## Compiling the dts ##################'
	-cp build/linux/scripts/dtc/dtc build/dts
	-cp host-tools/dts2dtb.sh build/dts
	cd build/dts/ && ./dts2dtb.sh $(target)


# RISC-V opensbi
PHONY += opensbi
opensbi:
	@echo '################## Building the opensbi ##################'
	@make -C build/opensbi PLATFORM=uctechip/$(target) FW_PAYLOAD_PATH=$(CURDIR)/build/linux/vmlinux.bin FW_PAYLOAD_FDT_PATH=$(CURDIR)/build/dts/$(target).dtb

# Image is used to build the kernel when you changed the core of Linux kernel
PHONY += Image
Image:	kernel dtb opensbi
	@mkdir -p build/output
	-cp build/opensbi/build/platform/uctechip/$(target)/firmware/fw_payload.elf build/output/Image

# This is used for building all the sources
PHONY += all
all: preconfig sync rootfs Image

# CLEAN
PHONY += clean
clean: 	
	@make -C build/busybox clean
	@make -C build/linux clean
	@make -C build/opensbi clean
	@rm -f build/dts/$(target).dtb
	@rm -f build/output/Image

# REMOVE the build
PHONY += distclean
distclean:
	@rm -rf build
	@rm -rf .config*


PHONY += help
help:
	@echo 'Cleaning:'
	@echo '	clean			- delete temporary files created by build'
	@echo '	distclean		- delete all non-source files (including .config)'
	@echo 
	@echo 'Build:'
	@echo '	all			- Image contains rootfs, Linux kernel and opensbi'
	@echo '	Image			- Linux kernel and opensbi(aimed to rebuild when changge the kernel code'
	@echo '	opensbi			- build the opensbi code, which needs the Linux kernel and dtb'
	@echo '	dtb			- build the device tree binary, which needs the dtc build by Linux'
	@echo '	kernel			- build the Linux kernel'
	@echo '	rootfs			- use busybox to build the filesystem for the Linux kernel'
	@echo
	@echo 'Other:'
	@echo '	sync			- create a copy of sources code and put them into directory build'
	@echo '	menuconfig		- interactive curses-based configurator'
	@echo '	list-defconfigs		- show the defconfig'
	@echo '	make XXX-defconfig	- use the defconfig as the build config'
	@echo '	preconfig		- check if exist the .config'
	@echo

.PHONY: $(PHONY)
