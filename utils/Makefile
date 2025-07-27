# Use mingw32-make as the command, not make :/

# Compiler
CC = gcc

# Compiler flags
CFLAGS = -Ofast -lm

# Source files
SRC = dft.c 

# Output executable
TARGET = dft.exe

# Default target
all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRC)

# Clean target
.PHONY: clean
clean:
	del /Q $(TARGET)