#!/bin/bash
set -e

echo "warp start"

# 定义文件下载地址
MASQUE_PLUS_URL="https://cdn.jsdelivr.net/gh/masx200/singbox-nodejs-warp-xray-tunnel@main/masque-plus.zip"
USQUE_URL="https://cdn.jsdelivr.net/gh/masx200/singbox-nodejs-warp-xray-tunnel@main/usque.zip"

# 检查并下载 masque-plus
if [ ! -f "./masque-plus" ]; then
    echo "下载 masque-plus..."
    rm masque-plus.zip || true
    wget -v -O masque-plus.zip "$MASQUE_PLUS_URL"
    unzip -o masque-plus.zip
    rm masque-plus.zip
    chmod +x ./masque-plus
    echo "masque-plus 下载并设置完成"
else
    echo "masque-plus 已存在，跳过下载"
fi

# 检查并下载 usque
if [ ! -f "./usque" ]; then
    echo "下载 usque..."
    rm usque.zip || true
    wget  -v -O usque.zip "$USQUE_URL"
    unzip -o usque.zip
    rm usque.zip
    chmod +x ./usque
    echo "usque 下载并设置完成"
else
    echo "usque 已存在，跳过下载"
fi



while true; do
    
    
       ./masque-plus "-bind" "0.0.0.0:1080" "-username" "hp40emnw108got6a67p2isj1x65qwjtz60fh5dtl7nhjhor3va" "--password" "i7esr1nwxcil034gslw4sdzjyfejfvf5xiaagx4x286nw6l3ff"  "-sni"  "gitlab.io" "-dns" "1.1.1.1,8.8.8.8,94.140.14.140" "-scan" "-4"                "-range4"                   "162.159.199.2/32"
    
    
    
    sleep 10
    
    ./masque-plus "-bind" "0.0.0.0:1080" "-username" "hp40emnw108got6a67p2isj1x65qwjtz60fh5dtl7nhjhor3va" "--password" "i7esr1nwxcil034gslw4sdzjyfejfvf5xiaagx4x286nw6l3ff"  "-sni"  "gitlab.io" "-dns" "1.1.1.1,8.8.8.8,94.140.14.140" "-scan" "-4"                "-range4"                   "162.159.198.2/32"
    
    
    
    sleep 10
done