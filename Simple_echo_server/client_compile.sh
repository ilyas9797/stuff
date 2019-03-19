#!/bin/bash

nasm -f elf client.asm
ld -m elf_i386 -o client client.o