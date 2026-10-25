#!/bin/bash
# memory usage percentage
free | awk '/Mem:/ {printf "%d", $3/$2*100}'
