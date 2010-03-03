##############################################################################
# Generic Makefile for following parts AT90USBx ATMegaxUx
###############################################################################

OUTPUT = build

# General Flags
TARGET = $(PROJECT).elf
CC = avr-gcc
MAKECFG   = config.mk

# Options common to compile, link and assembly rules
COMMON = -mmcu=$(MCU)

# Compile options common for all C compilation units.
CFLAGS = $(COMMON)
CFLAGS += -std=c99 -Wall -gdwarf-2 -Os -fsigned-char -ffunction-sections
CFLAGS += -MD -MP -MF $(OUTPUT)/dep/$(@F).d 

# Assembly specific flags
ASMFLAGS = $(COMMON)
ASMFLAGS += -x assembler-with-cpp -Wa,-gdwarf2

# Linker flags
LDFLAGS = $(COMMON)
LDFLAGS += -Wl,-Map=$(PROJECT).map,--cref,--gc-sections,--relax

# Intel Hex file production flags
HEX_FLASH_FLAGS = -R .eeprom

# Eeprom file production flags
HEX_EEPROM_FLAGS = -j .eeprom
HEX_EEPROM_FLAGS += --set-section-flags=.eeprom="alloc,load"
HEX_EEPROM_FLAGS += --change-section-lma .eeprom=0

# Include Directories
INCLUDES = -I"." -I"conf" -I"at90usb128" -I"common" 

# Include Source files list and part informations
include $(MAKECFG)

# Create objects files list with sources files
OBJECTS  = $(CSRCS:.c=.o) $(ASSRCS:.s=.o)


## Build
.PHONY: all
all: $(TARGET) $(PROJECT).hex size

## Clean target
.PHONY: clean
clean:
	@echo "Clean project"
	-rm -rf $(OUTPUT)/dep/* $(OBJECTS) $(PROJECT).elf $(PROJECT).hex $(PROJECT).eep $(PROJECT).map

## Rebuild the project.
.PHONY: rebuild
rebuild: clean all


## Compile

.PHONY: objfiles
objfiles: $(OBJECTS)

# create object files from C source files.
%.o: %.c
	@echo 'Building file: $<'
	@$(shell mkdir $(OUTPUT) 2>/dev/null)
	@$(shell mkdir $(OUTPUT)/dep 2>/dev/null)
	@$(CC) $(INCLUDES) $(CFLAGS) -c $< -o $(@)
	
# Preprocess & assemble: create object files from assembler source files.
%.o: %.s
	@echo 'Building file: $<'
	@$(shell mkdir $(OUTPUT) 2>/dev/null)
	@$(shell mkdir $(OUTPUT)/dep 2>/dev/null)
	@$(CC) $(INCLUDES) $(ASMFLAGS) -c $< -o $(@)


## Link
$(TARGET): $(OBJECTS)
	@echo "Linking"
	@$(CC) $(LDFLAGS) $(OBJECTS) $(LINKONLYOBJECTS) $(LIBDIRS) $(LIBS) -o $(TARGET)

%.hex: $(TARGET)
	@echo "Create hex file"
	@avr-objcopy -O ihex $(HEX_FLASH_FLAGS)  $< $@

%.eep: $(TARGET)
	@echo "Create eep file"
	@avr-objcopy $(HEX_EEPROM_FLAGS) -O ihex $< $@  || exit 0

%.lss: $(TARGET)
	@echo "Create lss file"
	@avr-objdump -h -S $< > $@

size: ${TARGET}
	@avr-size -C --mcu=${MCU} ${TARGET}

