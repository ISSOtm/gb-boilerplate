#!/usr/bin/env python3

from sys import argv


with open(argv[1], "rb") as input:
    with open(argv[2], "wb") as output:    
        output.write(bytes((byte ^ 0x80  for byte in input.read())))
