include ./Upload.in
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

RISCV_GDB	= riscv64-unknown-elf-gdb

export CROSS_COMPILE

# Get the PATH of GNU
GCC_PATH=$(shell which $(CC))
GNU_BIN=$(dir $(GCC_PATH))
GNU_PATH=$(shell dirname $(GNU_BIN))
GNU_LIB=$(join $(GNU_PATH), /sysroot/lib)

GDB_UPLOAD_ARGS ?= --batch
GDB_UPLOAD_CMDS += -ex "set remotetimeout 240"
GDB_UPLOAD_CMDS += -ex "target extended-remote $(HOST_IP):$(GDB_PORT)"
GDB_UPLOAD_CMDS += -ex "monitor reset halt"
GDB_UPLOAD_CMDS += -ex "load"
GDB_UPLOAD_CMDS += -ex 'thread apply all set $$dpc=0x40000000'
GDB_UPLOAD_CMDS += -ex "monitor resume"
GDB_UPLOAD_CMDS += -ex "quit"


ifndef CONFIG_HART_NUM
  CONFIG_HART_NUM = 1
endif

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
	@mkdir -p build/dts
	@cp defconfig/dts/$(CONFIG_HART_NUM)/* build/dts

# rootfs 
PHONY += rootfs
rootfs: 
	@echo '################## Building the rootfs ##################'
	@make -C build/busybox 
	@make -C build/busybox install
	@cp -arf $(GNU_LIB)/*so* build/rootfs/lib

# Linux Kernel
PHONY += kernel
kernel:
	@echo '################## Building the kernel ##################'
	@make -C build/linux ARCH=riscv -j4 
	$(OBJCOPY) -O binary build/linux/vmlinux build/linux/vmlinux.bin

#Fixed frequency for dts
PHONY += fix_dts
fix_dts:
ifdef CONFIG_Debug
	$(shell sed -i "s/#define.*SYS_CLK.*/#define SYS_CLK $(CONFIG_SYS_CLK)/" build/dts/HWJ.dtsi\
	&& sed -i "s/#define.*RTC_CLK.*/#define RTC_CLK $(CONFIG_RTC_CLK)/" build/dts/HWJ.dtsi)
endif

# dtb
PHONY += dtb
dtb:	fix_dts
	@echo '################## Compiling the dts ##################'
	-cp build/linux/scripts/dtc/dtc build/dts
	-cp host-tools/dts2dtb.sh build/dts
	cd build/dts/ && ./dts2dtb.sh $(target)

#Fixed frequency for opensbi
PHONY += fix_opensbi
fix_opensbi:
	$(shell sed -i "s/#define.*WH_HART_COUNT.*/#define WH_HART_COUNT $(CONFIG_HART_NUM)/" build/opensbi/platform/uctechip/$(target)/platform.h)

ifdef CONFIG_Debug
	$(shell sed -i "s/#define.*WH_SYS_CLK.*/#define WH_SYS_CLK $(CONFIG_SYS_CLK)/" build/opensbi/platform/uctechip/$(target)/platform.h)
endif

#opensbi configuration
OPENSBI_CFLAGS = PLATFORM=uctechip/$(target) FW_PAYLOAD_PATH=$(CURDIR)/build/linux/vmlinux.bin FW_PAYLOAD_FDT_PATH=$(CURDIR)/build/dts/$(target).dtb

ifdef CONFIG_Debug
OPENSBI_CFLAGS += FW_PAYLOAD_FDT_ADDR=$(CONFIG_DTB_ADDRESS)
endif

# RISC-V opensbi
PHONY += opensbi
opensbi:	fix_opensbi
	@echo '################## Building the opensbi ##################'
	make -C build/opensbi $(OPENSBI_CFLAGS)

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
	@make -C build/linux clean
	@make -C build/opensbi clean
	@rm -f build/dts/$(target).dtb
	@rm -f build/output/Image
	@make -C build/busybox clean

# REMOVE the build
PHONY += distclean
distclean:
	@rm -rf build
	@rm -rf .config*


PHONY += upload
upload:
	$(RISCV_GDB) build/output/Image $(GDB_UPLOAD_ARGS) $(GDB_UPLOAD_CMDS)


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
	@echo 'Upload:'
	@echo '	upload			- upload the Image to FPGA board'
	@echo 
	@echo 'Other:'
	@echo '	sync			- create a copy of sources code and put them into directory build'
	@echo '	menuconfig		- interactive curses-based configurator'
	@echo '	list-defconfigs		- show the defconfig'
	@echo '	make XXX-defconfig	- use the defconfig as the build config'
	@echo '	preconfig		- check if exist the .config'
	@echo

.PHONY: $(PHONY)
