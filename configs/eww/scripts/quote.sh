#!/bin/bash
# quote (waybar style: fortune -s)
fortune -s 2>/dev/null | tr '\n' ' ' | cut -c1-60
