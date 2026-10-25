#!/bin/bash
# cpu usage percentage (1s sample)
prev_idle=$(grep -E '^cpu ' /proc/stat | awk '{print $5}')
prev_total=$(grep -E '^cpu ' /proc/stat | awk '{print $2+$3+$4+$5+$6+$7+$8}')
sleep 1
cur_idle=$(grep -E '^cpu ' /proc/stat | awk '{print $5}')
cur_total=$(grep -E '^cpu ' /proc/stat | awk '{print $2+$3+$4+$5+$6+$7+$8}')
d_idle=$((cur_idle - prev_idle))
d_total=$((cur_total - prev_total))
if [ "$d_total" -eq 0 ]; then echo 0; else echo $(( (d_total - d_idle) * 100 / d_total )); fi
