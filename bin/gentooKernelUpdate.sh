#!/bin/bash

make -j17  && make modules_install && make install && grub-install --efi-directory=/efi/ && grub-mkconfig  -o /boot/grub/grub.cfg
