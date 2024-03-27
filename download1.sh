#!/bin/bash

# 循环下载文件500次，覆盖下载
for ((i=50; i<=50000; i++))
do
    wget -N https://maxadmin.k888k.top/theme/wordpress-bob/js/chunk-vendors.dac02230.js -O chunk-vendors.dac02230.js
done
