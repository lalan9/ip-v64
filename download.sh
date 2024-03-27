#!/bin/bash

# 循环下载文件500次
for ((i=999; i<=9999999; i++))
do
    wget https://hmkj3.com/theme/pink/assets/i18n/en-US.js -P /path/to/save
done
