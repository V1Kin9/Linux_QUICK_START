#!/bin/sh
echo "SUBSYSTEMS==\"usb\", ATTRS{idVendor}==\"0403\", ATTRS{idProduct}==\"6010\", GROUP=\"$(whoami)\", MODE=\"0666\"" > 99-myusb.rules
echo "SUBSYSTEMS==\"usb\", ATTRS{idVendor}==\"0403\", ATTRS{idProduct}==\"6014\", GROUP=\"$(whoami)\", MODE=\"0666\"" >> 99-myusb.rules
