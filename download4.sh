#!/bin/bash

# 循环下载文件500次，覆盖下载
for ((i=50; i<=50000; i++))
do
    wget -N https://www.cnnic.xyz/_next/static/chunks/framework-c16fc4c01675a4d8.js -O framework-c16fc4c01675a4d8.js
done
