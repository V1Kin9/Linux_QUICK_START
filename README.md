---
typora-root-url: ./
---

# Linux_QUICK_START
This is a tool that quickly help you to build up the Linux on HWJ-SoC. Now it is used for building the kernel for UCTECHIP WH series processors. 

This article is roughly divided into four parts:

[Building the toolchain](#Building the toolchain)

[Building the OpenOCD](#Building the OpenOCD)

[Building the Image](#Building the Image)

[Upload the Image](#Upload the Image)



## Building the toolchain

### Prerequisites

Several standard packages are needed to build the toolchain.  On Ubuntu, executing the following command should suffice:

```
$ sudo apt-get install autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev
```

On Fedora/CentOS/RHEL OS, executing the following command should suffice:

```
$ sudo yum install autoconf automake python3 libmpc-devel mpfr-devel gmp-devel gawk  bison flex texinfo patchutils gcc gcc-c++ zlib-devel expat-devel
```

On OS X, you can use [Homebrew](http://brew.sh) to install the dependencies:

```
$ brew install python3 gawk gnu-sed gmp mpfr libmpc isl zlib expat
```



### Download the toolchain sources

```
$ git clone --recursive https://github.com/riscv/riscv-gnu-toolchain
```

​	or

```
$ git clone https://github.com/riscv/riscv-gnu-toolchain
$ cd riscv-gnu-toolchain
$ git submodule update --init --recursive
```



Checkout to the branch 

```
$ git checkout 2c037e631e27bc01582476f5b3c5d5e9e51489b8 -b tmp
$ git submodule update
```



### Installation

#### glibc

If you run the Linux on a 32-bit processor, then type the following command:

```
$ ./configure --prefix=/path/you/want/to/install --with-arch=rv32gc --with-abi=ilp32d
$ make linux
```

If you run on a 64-bit processor, run the following command:

```
$ ./configure --prefix=/path/you/want/to/install --with-arch=rv64gc --with-abi=lp64d
$ make linux
```
#### newlibc

Build the newlib toolchain:

```
$ ./configure --prefix=/path/you/want/to/install --enable-multilib
$ make
```

#### Add the path to system environment

Add the installation path of toolchain to the system environment:

``` 
$ export PATH=$(PATH):/path/you/want/to/install/bin
```

>  I suggest you to add the *toolchain path* to the system environment by adding it to the ~/.bashrc
>
> So that it will be convenient to compile next time



Test the toolchain by typing the following command to the Termial:

```
$ riscv[32|64]-unknown-linux-gcc -v
$ riscv64-unknown-elf-gcc -v
```

You will see the version information if you compile it completely and add the installation path to the system environment successfully.



## Building the OpenOCD

### Getting the sources of code

```
$ git clone https://github.com/UCTECHIP/riscv-openocd.git
```

### Building the source code

```
$ cd riscv-openocd
$ ./bootstrap
$ ./configure --enable-ftdi --prefix=/path/you/want/to/install
$ make && make install
```

#### Add the path to system environment

Add the installation path of OpenOCD to the system environment:

``` 
$ export PATH=$(PATH):/path/you/want/to/install/bin
```

Test the OpenOCD by typing the following command to the Termial:

```
￼$ openocd -v 
```



You will see the version information if you compile it completely and add the installation path to the system environment successfully.

## Building the Image

### Getting the sources of code

This repository uses submodules. You need the --recursive option to fetch the submodules automatically

```
$ git clone --recursive https://github.com/UCTECHIP/Linux_QUICK_START.git
```
Alternatively :
```
$ git clone https://github.com/UCTECHIP/Linux_QUICK_START.git 

$ cd Linux_QUICK_START

$ git submodule update --init --recursive
```



### Building the Linux Image 

1. First you need to select the processor,hart number and FPGA develop board after typing the command:

```
$ make menuconfig
```

![](/figures/configure.png)

You can also run  `$ make list-defconfigs` to see the defconfigs of WH processors. 

For example, you can run `$ make WH32-HWJ_defconfig` to select WH32 as the building target for LS-Extended Board.

   

2. When you done with the configuration, you should run `$ make all` to start building the Linux Image which includes the rootfs, build with busybox, and opensbi.

P.S. You should type the  password of you PC for creating the character device *console* and *null*

![](/figures/passward.png)



3. You can find the finally Image in the directory *build/output*.

![](/figures/complete.png)



## Upload the Image

For some reasons, we only use the newlib-toolchain to upload the program. If you don't have a newlib toolchain, you should build a [newlib-toolchain](#newlibc).



1. Change the **HOST_IP** with your PC's IP in the file *Upload.in*

2. Make sure you have already connected your PC to the FPGA board. And then configure your serial port correctly(115200,8E1).

3. Use the Openocd to connect:
```
$ make run_opneocd
```
4. Open another terminal and type the following command to upload the Image to the DDR of the FPGA board:

```
$ make upload
```

If everything right, you can find the similar information in your serial port.

____                    _____ ____ _____
```
OpenSBI v0.6
   ____                    _____ ____ _____
  / __ \                  / ____|  _ \_   _|
 | |  | |_ __   ___ _ __ | (___ | |_) || |
 | |  | | '_ \ / _ \ '_ \ \___ \|  _ < | |
 | |__| | |_) |  __/ | | |____) | |_) || |_
  \____/| .__/ \___|_| |_|_____/|____/_____|
        | |
        |_|

Platform Name          : WH
Platform HART Features : RV64ACDFIMSUX
Platform Max HARTs     : 2
Current Hart           : 0
Firmware Base          : 0x40000000
Firmware Size          : 72 KB
Runtime SBI Version    : 0.2

MIDELEG : 0x0000000000000222
MEDELEG : 0x000000000000b109
PMP0    : 0x0000000040000000-0x000000004001ffff (A)
PMP1    : 0x0000000000000000-0x00000007ffffffff (A,R,W,X)
[    0.000000] OF: fdt: Ignoring memory range 0x40000000 - 0x40200000
[    0.000000] Linux version 4.19.0 (viking@viking-uctechip) (gcc version 9.2.0 (GCC)) #2 SMP Fri Dec 
25 17:06:10 CST 2020
[    0.000000] bootconsole [early0] enabled
[    0.000000] initrd not found or empty - disabling initrd
[    0.000000] Zone ranges:
[    0.000000]   DMA32    [mem 0x0000000040200000-0x000000007fffffff]
[    0.000000]   Normal   [mem 0x0000000080000000-0x000007ffffffffff]
[    0.000000] Movable zone start for each node
[    0.000000] Early memory node ranges
[    0.000000]   node   0: [mem 0x0000000040200000-0x000000007fffffff]
[    0.000000] Initmem setup node 0 [mem 0x0000000040200000-0x000000007fffffff]
[    0.000000] On node 0 totalpages: 261632
[    0.000000]   DMA32 zone: 4088 pages used for memmap
[    0.000000]   DMA32 zone: 0 pages reserved
[    0.000000]   DMA32 zone: 261632 pages, LIFO batch:63
[    0.000000] elf_hwcap is 0x112d
[    0.000000] percpu: Embedded 15 pages/cpu @(____ptrval____) s24384 r8192 d28864 u61440
[    0.000000] pcpu-alloc: s24384 r8192 d28864 u61440 alloc=15*4096
[    0.000000] pcpu-alloc: [0] 0 [0] 1 
[    0.000000] Built 1 zonelists, mobility grouping on.  Total pages: 257544
[    0.000000] Kernel command line: console=ttyWH0,115200n8  debug loglevel=8
[    0.000000] Dentry cache hash table entries: 131072 (order: 8, 1048576 bytes)
[    0.000000] Inode-cache hash table entries: 65536 (order: 7, 524288 bytes)
[    0.000000] Sorting __ex_table...
[    0.000000] Memory: 1013896K/1046528K available (2046K kernel code, 188K rwdata, 908K rodata, 11175
K init, 239K bss, 32632K reserved, 0K cma-reserved)
[    0.000000] random: get_random_u64 called from cache_random_seq_create+0x3a/0xd2 with crng_init=0
[    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=2, Nodes=1
[    0.000000] rcu: Hierarchical RCU implementation.
[    0.000000] rcu:     RCU restricting CPUs from NR_CPUS=8 to nr_cpu_ids=2.
[    0.000000] rcu: Adjusting geometry for rcu_fanout_leaf=16, nr_cpu_ids=2
[    0.000000] NR_IRQS: 0, nr_irqs: 0, preallocated irqs: 0
[    0.000000] plic: mapped 15 interrupts to 2 (out of 4) handlers.
[    0.000000] clocksource: riscv_clocksource: mask: 0xffffffffffffffff max_cycles: 0x171024e6b, max_i
dle_ns: 1763180809207 ns
[    0.000000] Console: colour dummy device 80x25
[    0.010000] Calibrating delay loop (skipped), value calculated using timer frequency.. 3.12 BogoMIP
S (lpj=15625)
[    0.020000] pid_max: default: 4096 minimum: 301
[    0.030000] Mount-cache hash table entries: 2048 (order: 2, 16384 bytes)
[    0.040000] Mountpoint-cache hash table entries: 2048 (order: 2, 16384 bytes)
[    0.070000] rcu: Hierarchical SRCU implementation.
[    0.090000] smp: Bringing up secondary CPUs ...
[    0.100000] smp: Brought up 1 node, 2 CPUs
[    0.120000] devtmpfs: initialized
[    0.140000] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 19112604462
750000 ns
[    0.150000] futex hash table entries: 16 (order: -2, 1024 bytes)
[    0.160000] NET: Registered protocol family 16
[    0.240000] clocksource: Switched to clocksource riscv_clocksource
[    0.340000] NET: Registered protocol family 1
[   16.950000] workingset: timestamp_bits=46 max_order=18 bucket_order=0
[   17.140000] Block layer SCSI generic (bsg) driver version 0.4 loaded (major 254)
[   17.150000] io scheduler noop registered
[   17.160000] io scheduler deadline registered
[   17.170000] io scheduler cfq registered (default)
[   17.180000] io scheduler mq-deadline registered
[   17.190000] io scheduler kyber registered
[   17.800000] UCTECHIP WH UART device driver
[   17.800000] 10000010.serial: ttyWH0 at MMIO 0x10000010 (irq = 1, base_baud = 3125000) is a WH UART
[   17.820000] console [ttyWH0] enabled
[   17.820000] console [ttyWH0] enabled
[   17.830000] bootconsole [early0] disabled
[   17.830000] bootconsole [early0] disabled
[   17.990000] loop: module loaded
[   18.000000] NET: Registered protocol family 17
[   18.010000] NET: Registered protocol family 15
[   18.020000] wh_uart: able to attach WH UART 0 interrupt vector=1
[   18.240000] Freeing unused kernel memory: 11172K
[   18.240000] This architecture does not have kernel memory protection.
[   18.250000] Run /init as init process

Please press Enter to activate this console. 
```

