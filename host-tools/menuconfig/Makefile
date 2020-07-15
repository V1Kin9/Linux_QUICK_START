CC ?= gcc

lxdialog := lxdialog/checklist.o
lxdialog += lxdialog/util.o
lxdialog += lxdialog/inputbox.o
lxdialog += lxdialog/textbox.o
lxdialog += lxdialog/yesno.o
lxdialog += lxdialog/menubox.o

mconf-objs := mconf.o
mconf-objs += zconf.tab.o
mconf-objs += $(lxdialog)

conf-objs := conf.o
conf-objs += zconf.tab.o

clean-files	:= mconf conf
clean-files += $(mconf-objs)
clean-files += $(conf-objs)

all: mconf conf
	
$(obj)/%.o: %.c
	$(CC) -c $< -o $@

mconf: $(mconf-objs)
	$(CC) $(mconf-objs) -o mconf -lncurses

conf: $(conf-objs)
	$(CC) $(conf-objs) -o conf

clean:
	@rm -f $(clean-files)
