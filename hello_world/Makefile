CROSS_COMPILE ?= ~/lfs/rpi2/min_img/buildroot-2015.11.1/output/host/usr/bin/arm-buildroot-linux-uclibcgnueabihf-

CC=${CROSS_COMPILE}gcc
CFLAGS=-I./
DEPS = 
OBJ = hello.o 

.PHONY: clean

%.o: %.c $(DEPS)
	$(CC) -c -o $@ $< $(CFLAGS)

hello: $(OBJ)
	$(CC) -o $@ $^ $(CFLAGS)

clean:
	rm -f *.o hello
