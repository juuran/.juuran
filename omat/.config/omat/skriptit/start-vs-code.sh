#!/bin/bash
/usr/bin/flatpak override --user --filesystem=/tmp com.visualstudio.code &> /dev/null
/usr/bin/flatpak run --file-forwarding com.visualstudio.code "$@" &> /dev/null
