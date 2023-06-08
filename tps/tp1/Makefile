#CHAIN=arm-none-eabi
CHAIN=arm-linux-gnueabihf
CFLAGS=-std=gnu99 -Wall -mcpu=cortex-a8

OBJ=obj/
BIN=bin/
INC=inc/
SRC=
LST=lst/

all: $(BIN)ejemplo1.bin $(OBJ)ejemplo1.elf

$(BIN)ejemplo1.bin: $(OBJ)ejemplo1.elf
	$(CHAIN)-objcopy -O binary $< $@


$(OBJ)ejemplo1.elf: $(OBJ)asm_code_tp1.o
	@echo "Linkeando ... "
	mkdir -p obj
	mkdir -p lst
	$(CHAIN)-ld -g -T linker_script.ld $(OBJ)*.o -o $(OBJ)ejemplo1.elf -Map $(LST)ejemplo1.map
	@echo "Linkeo finalizado!!"
	@echo ""
	@echo "Generando archivos de información: mapa de memoria y símbolos"
	readelf -a $(OBJ)ejemplo1.elf > $(LST)ejemplo1_elf.txt
	$(CHAIN)-objdump -D $(OBJ)ejemplo1.elf > $(LST)ejemplo1.lst

$(OBJ)asm_code_tp1.o: $(SRC)asm_code_tp1.s
	@echo ""
	mkdir -p bin
	mkdir -p obj
	mkdir -p lst
	@echo "Ensamblando asm_code_tp1.s ..."
	$(CHAIN)-as $(SRC)asm_code_tp1.s -g -o $(OBJ)asm_code_tp1.o -a > $(LST)asm_code_tp1.lst

clean:
	rm -rf $(OBJ)*.o $(OBJ)*.elf $(OBJ)/ $(BIN)*.bin $(BIN)/ $(LST)*.lst $(LST)*.txt $(LST)*.map $(LST)/


run:
	qemu-system-arm -M realview-pb-a8 -m 32M -no-reboot -nographic -monitor telnet:127.0.0.1:1234,server,nowait -S -gdb tcp::2159 -kernel ./$(BIN)/ejemplo1.bin

debug:
	ddd --debugger gdb-multiarch $(OBJ)ejemplo1.elf
