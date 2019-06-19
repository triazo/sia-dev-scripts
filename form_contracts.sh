#!/bin/bash

# Easily form contracts using `us`
for addr in $(siac hostdb -v | egrep -o '([a-f0-9]){64}' |tr '\n' ' '); do user form $addr 10KS 20000; done
