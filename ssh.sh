#!/bin/bash

pacman -S ufw openssh nano --noconfirm

ufw allow ssh

ufw enable

systemctl start sshd

passwd

ip -a
