# Linux_QUICK_START
This is a tool that quickly help you to build up the Linux on HWJ-SoC. Now it is used for building the kernel for UCTECHIP WH series processors. 



### Building the toolchain

#### Prerequisites

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



#### Download the toolchain sources

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



#### Installation

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



Add the installation path of toolchain to the system environment:

``` 
$ export PATH=$(PATH):/path/you/want/to/install/bin
```

P.S. I suggest you to add the *toolchain path* to the system environment by adding it to the ~/.bashrc



Test the toolchain by typing the following command to the Termial:

```
$ riscv[32|64]-unknown-linux-gcc -v
```

You will see the version information if you compile it completely and add the installation path to the system environment successfully.



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

1. First, you need to run the command below to create a copy of sources into the *build*.
```
$ make sync
```

   If you want to change the code, you can change the code in directory *build* temporarily.

   When you want to get into the develop of the source code, I suggest you to change the code in the directory *src*, which will not be deleted when you run `$ make distclean`

   

2. Then you need to select the processor and hart number by typing the command:

```
$ make menuconfig
```

   You can also run  `$ make list-defconfigs` to see the defconfigs of WH processors. 

   For example, you can run `$ make WH32-HWJ_defconfig` to select WH32 as the building target for LS-Extended Board.

   

3. When you done with the configuration, you should run `$ make all` to start building the Linux Image which includes the rootfs, build with busybox, and opensbi.

   You can find the finally Image in the directory *build/output*.

   
P.S. You should type the  password of you PC for creating the character device *console* and *null*

```
------Create rootfs directons start...--------
--------Create root,dev....----------
Make node in dev/console dev/null
Please input the passwd of your PC for creating the console and null
[sudo] password for viking: 
```

