#!/bin/bash

nasm -f elf server.asm
ld -m elf_i386 -o server server.o