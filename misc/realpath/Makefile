INSTALL_PATH=~/bin
CC=gcc

.PHONY=install

install: realpath
	mkdir -p $(INSTALL_PATH)
	cp realpath ~/bin	

realpath: realpath.c
	$(CC) -o $@ $?
