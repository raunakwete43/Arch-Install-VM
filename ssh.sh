#!/bin/bash

pacman -Sy ufw openssh

ufw allow ssh

ufw enable

systemctl start sshd

passwd
9443
9443
