CFLAGS = -g -O0
CC = clang

.PHONY: all
all: build/mb build/find
	./build/mb find --name '*.c'

build/mb: main.c build
	$(CC) $(CFLAGS) -o $@ $<

build/find: find.c build
	$(CC) $(CFLAGS) -o $@ $<

build:
	mkdir build

.PHONY: clean
clean:
	rm -r build/
