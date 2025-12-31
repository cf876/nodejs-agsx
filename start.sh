#!/bin/ash  # [Alpine适配] 改为ash解释器（Alpine默认）
# 若你安装了bash，也可保留#!/bin/bash

# =========================
# 老王sing-box四合一脚本（Alpine amd64 非root适配版）
# 适配Alpine Linux musl libc环境
# =========================

export LANG=en_US.UTF-8
# 定义颜色（ash兼容）
re="\033[0m"
red="\033[1;91m"
green="\e[1;32m"
yellow="\e[1;33m"
purple="\e[1;35m"
skyblue="\e[1;36m"

# [Alpine适配] 简化颜色函数（ash兼容）
red() { echo -e "\e[1;91m$1\033[0m"; }
green() { echo -e "\e[1;32m$1\033[0m"; }
yellow() { echo -e "\e[1;33m$1\033[0m"; }
purple() { echo -e "\e[1;35m$1\033[0m"; }
skyblue() { echo -e "\e[1;36m$1\033[0m"; }

# 【核心修改】使用用户目录替代系统目录
USER_HOME=$(eval echo ~${SUDO_USER:-$USER})
server_name="sing-box"
work_dir="${USER_HOME}/.sing-box"
config_dir="${work_dir}/config.json"
client_dir="${work_dir}/url.txt"
log_dir="${work_dir}/logs"
export vless_port=${PORT:-$(shuf -i 1025-65000 -n 1)}  # 仅用1024以上端口
export CFIP=${CFIP:-'cf.877774.xyz'} 
export CFPORT=${CFPORT:-'443'} 

# 检查命令是否存在函数（ash兼容）
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 获取ip（适配Alpine的curl）
get_realip() {
    ip=$(curl -4 -sm 2 ip.sb)
    ipv6() { curl -6 -sm 2 ip.sb; }
    if [ -z "$ip" ]; then
        echo "[$(ipv6)]"
    elif curl -4 -sm 2 http://ipinfo.io/org | grep -qE 'Cloudflare|UnReal|AEZA|Andrei'; then
        echo "[$(ipv6)]"
    else
        resp=$(curl -sm 8 "https://status.eooce.com/api/$ip" | jq -r '.status')
        if [ "$resp" = "Available" ]; then
            echo "$ip"
        else
            v6=$(ipv6)
            [ -n "$v6" ] && echo "[$v6]" || echo "$ip"
        fi
    fi
}

# 下载并安装 sing-box（Alpine amd64 适配）
install_singbox() {
    purple "正在安装sing-box到用户目录，请稍后..."
    
    # 创建目录
    mkdir -p "${work_dir}" "${log_dir}" && chmod 777 "${work_dir}" "${log_dir}"

    # [Alpine适配] 强制指定amd64架构（Alpine amd64识别为x86_64）
    ARCH="amd64"

    # 下载二进制文件到用户目录（适配Alpine的musl版本）
    curl -sLo "${work_dir}/qrencode" "https://$ARCH.ssss.nyc.mn/qrencode"
    curl -sLo "${work_dir}/sing-box" "https://$ARCH.ssss.nyc.mn/sbx"
    curl -sLo "${work_dir}/argo" "https://$ARCH.ssss.nyc.mn/bot"
    chmod +x "${work_dir}/sing-box" "${work_dir}/argo" "${work_dir}/qrencode"

    # 生成随机端口和密码
    nginx_port=$(($vless_port + 1)) 
    tuic_port=$(($vless_port + 2))
    hy2_port=$(($vless_port + 3)) 
    uuid=$(cat /proc/sys/kernel/random/uuid)
    password=$(< /dev/urandom tr -dc 'A-Za-z0-9' | head -c 24)
    output=$("${work_dir}/sing-box" generate reality-keypair)
    private_key=$(echo "${output}" | awk '/PrivateKey:/ {print $2}')
    public_key=$(echo "${output}" | awk '/PublicKey:/ {print $2}')

    # 生成自签名证书（用户目录，Alpine openssl兼容）
    openssl ecparam -genkey -name prime256v1 -out "${work_dir}/private.key"
    openssl req -new -x509 -days 3650 -key "${work_dir}/private.key" -out "${work_dir}/cert.pem" -subj "/CN=bing.com"
    
    # 检测DNS策略
    dns_strategy=$(ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1 && echo "prefer_ipv4" || (ping -c 1 -W 3 2001:4860:4860::8888 >/dev/null 2>&1 && echo "prefer_ipv6" || echo "prefer_ipv4"))

    # 生成配置文件（调整wireguard为用户级，所有流量走wireguard）
cat > "${config_dir}" << EOF
{
  "log": {
    "disabled": false,
    "level": "error",
    "output": "${log_dir}/sb.log",
    "timestamp": true
  },
  "dns": {
    "servers": [
      {
        "tag": "local",
        "address": "local",
        "strategy": "$dns_strategy"
      }
    ]
  },
  "ntp": {
    "enabled": true,
    "server": "time.apple.com",
    "server_port": 123,
    "interval": "30m"
  },
  "inbounds": [
    {
      "type": "vless",
      "tag": "vless-reality",
      "listen": "::",
      "listen_port": $vless_port,
      "users": [
        {
          "uuid": "$uuid",
          "flow": "xtls-rprx-vision"
        }
      ],
      "tls": {
        "enabled": true,
        "server_name": "www.iij.ad.jp",
        "reality": {
          "enabled": true,
          "handshake": {
            "server": "www.iij.ad.jp",
            "server_port": 443
          },
          "private_key": "$private_key",
          "short_id": [""]
        }
      }
    },
    {
      "type": "vmess",
      "tag": "vmess-ws",
      "listen": "::",
      "listen_port": 8001,
      "users": [
        {
          "uuid": "$uuid"
        }
      ],
      "transport": {
        "type": "ws",
        "path": "/vmess-argo",
        "early_data_header_name": "Sec-WebSocket-Protocol"
      }
    },
    {
      "type": "hysteria2",
      "tag": "hysteria2",
      "listen": "::",
      "listen_port": $hy2_port,
      "users": [
        {
          "password": "$uuid"
        }
      ],
      "ignore_client_bandwidth": false,
      "masquerade": "https://bing.com",
      "tls": {
        "enabled": true,
        "alpn": ["h3"],
        "min_version": "1.3",
        "max_version": "1.3",
        "certificate_path": "${work_dir}/cert.pem",
        "key_path": "${work_dir}/private.key"
      }
    },
    {
      "type": "tuic",
      "tag": "tuic",
      "listen": "::",
      "listen_port": $tuic_port,
      "users": [
        {
          "uuid": "$uuid",
          "password": "$password"
        }
      ],
      "congestion_control": "bbr",
      "tls": {
        "enabled": true,
        "alpn": ["h3"],
        "certificate_path": "${work_dir}/cert.pem",
        "key_path": "${work_dir}/private.key"
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "block"
    },
    {
      "type": "wireguard",
      "tag": "wireguard-out",
      "server": "engage.cloudflareclient.com",
      "server_port": 2408,
      "local_address": [
        "172.16.0.2/32",
        "2606:4700:110:851f:4da3:4e2c:cdbf:2ecf/128"
      ],
      "private_key": "eAx8o6MJrH4KE7ivPFFCa4qvYw5nJsYHCBQXPApQX1A=",
      "peer_public_key": "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=",
      "reserved": [82, 90, 51],
      "mtu": 1420
    }
  ],
  "route": {
    "rule_set": [
      {
        "tag": "openai",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo-lite/geosite/openai.srs",
        "download_detour": "direct"
      },
      {
        "tag": "netflix",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo-lite/geosite/netflix.srs",
        "download_detour": "direct"
      }
    ],
    "rules": [
      {
        "all": true,
        "outbound": "wireguard-out"
      }
    ],
    "final": "wireguard-out"
  }
}
EOF
}

# 生成节点和订阅链接（Alpine兼容）
get_info() {  
  yellow "\nip检测中,请稍等...\n"
  server_ip=$(get_realip)
  isp=$(curl -s --max-time 2 https://ipapi.co/json | tr -d '\n[:space:]' | sed 's/.*"country_code":"\([^"]*\)".*"org":"\([^"]*\)".*/\1-\2/' | sed 's/ /_/g' 2>/dev/null || echo "$hostname")

  # 获取Argo域名
  if [ -f "${log_dir}/argo.log" ]; then
      for i in 1 2 3 4 5; do  # [Alpine适配] ash不支持{1..5}，改为数字列表
          purple "第 $i 次尝试获取ArgoDomain中..."
          argodomain=$(sed -n 's|.*https://\([^/]*trycloudflare\.com\).*|\1|p' "${log_dir}/argo.log")
          [ -n "$argodomain" ] && break
          sleep 2
      done
  else
      restart_argo
      sleep 6
      argodomain=$(sed -n 's|.*https://\([^/]*trycloudflare\.com\).*|\1|p' "${log_dir}/argo.log")
  fi

  green "\nArgoDomain：${purple}$argodomain${re}\n"

  # 生成VMESS配置
  VMESS="{ \"v\": \"2\", \"ps\": \"${isp}\", \"add\": \"${CFIP}\", \"port\": \"${CFPORT}\", \"id\": \"${uuid}\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"${argodomain}\", \"path\": \"/vmess-argo?ed=2560\", \"tls\": \"tls\", \"sni\": \"${argodomain}\", \"alpn\": \"\", \"fp\": \"firefox\", \"allowlnsecure\": \"flase\"}"

  # 写入节点文件
  cat > ${client_dir} <<EOF
vless://${uuid}@${server_ip}:${vless_port}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.iij.ad.jp&fp=firefox&pbk=${public_key}&type=tcp&headerType=none#${isp}

vmess://$(echo "$VMESS" | base64 -w0)

hysteria2://${uuid}@${server_ip}:${hy2_port}/?sni=www.bing.com&insecure=1&alpn=h3&obfs=none#${isp}

tuic://${uuid}:${password}@${server_ip}:${tuic_port}?sni=www.bing.com&congestion_control=bbr&udp_relay_mode=native&alpn=h3&allow_insecure=1#${isp}
EOF

  # 生成订阅文件（Alpine base64兼容）
  base64 -w0 ${client_dir} > ${work_dir}/sub.txt
  chmod 644 ${work_dir}/sub.txt

  # 显示节点信息
  echo ""
  while IFS= read -r line; do echo -e "${purple}$line"; done < ${client_dir}
  
  # 显示订阅链接（Python HTTP服务）
  yellow "\n温馨提醒：需打开V2rayN等软件的「跳过证书验证」\n"
  green "订阅链接（需保持Python服务运行）：http://${server_ip}:${nginx_port}/${password}\n"
  "${work_dir}/qrencode" "http://${server_ip}:${nginx_port}/${password}"
  
  # 显示多格式订阅链接
  yellow "\n=========================================================================================="
  green "\nClash/Mihomo订阅链接：https://sublink.eooce.com/clash?config=http://${server_ip}:${nginx_port}/${password}\n"
  green "Sing-box订阅链接：https://sublink.eooce.com/singbox?config=http://${server_ip}:${nginx_port}/${password}\n"
  green "Surge订阅链接：https://sublink.eooce.com/surge?config=http://${server_ip}:${nginx_port}/${password}\n"
  yellow "==========================================================================================\n"
}

# 【非root核心】用nohup后台运行进程（Alpine兼容）
start_processes() {
    # 停止已有进程
    stop_processes

    # 启动sing-box
    nohup "${work_dir}/sing-box" run -c "${config_dir}" > "${log_dir}/sb.log" 2>&1 &
    echo $! > "${work_dir}/sb.pid"
    green "sing-box 已启动，PID: $(cat ${work_dir}/sb.pid)\n"

    # 启动argo隧道
    nohup "${work_dir}/argo" tunnel --url http://localhost:8001 --no-autoupdate --edge-ip-version auto --protocol http2 > "${log_dir}/argo.log" 2>&1 &
    echo $! > "${work_dir}/argo.pid"
    green "Argo隧道 已启动，PID: $(cat ${work_dir}/argo.pid)\n"

    # 启动Python HTTP服务（替代Nginx）
    nohup python3 -m http.server ${nginx_port} --directory "${work_dir}" --bind 0.0.0.0 > "${log_dir}/http.log" 2>&1 &
    echo $! > "${work_dir}/http.pid"
    green "Python订阅服务 已启动，PID: $(cat ${work_dir}/http.pid)\n"

    # 等待服务加载
    sleep 5
}

# 停止所有进程（Alpine兼容）
stop_processes() {
    # 停止sing-box
    if [ -f "${work_dir}/sb.pid" ]; then
        kill $(cat "${work_dir}/sb.pid") 2>/dev/null || true
        rm -f "${work_dir}/sb.pid"
    fi

    # 停止argo
    if [ -f "${work_dir}/argo.pid" ]; then
        kill $(cat "${work_dir}/argo.pid") 2>/dev/null || true
        rm -f "${work_dir}/argo.pid"
    fi

    # 停止Python HTTP服务
    if [ -f "${work_dir}/http.pid" ]; then
        kill $(cat "${work_dir}/http.pid") 2>/dev/null || true
        rm -f "${work_dir}/http.pid"
    fi

    # 清理残留进程（Alpine pgrep兼容）
    pkill -f "${work_dir}/sing-box" 2>/dev/null || true
    pkill -f "${work_dir}/argo" 2>/dev/null || true
    pkill -f "python3 -m http.server ${nginx_port}" 2>/dev/null || true
}

# 检查进程状态（Alpine适配，依赖procps-ng）
check_status() {
    green "=== 进程状态 ===\n"
    # 检查procps是否安装
    if ! command_exists "ps"; then
        red "未安装procps-ng，无法查看进程状态，请先执行：apk add procps-ng\n"
        return 1
    fi
    if ps -p $(cat "${work_dir}/sb.pid" 2>/dev/null) >/dev/null 2>&1; then
        green "sing-box: 运行中 (PID: $(cat ${work_dir}/sb.pid))"
    else
        red "sing-box: 未运行"
    fi

    if ps -p $(cat "${work_dir}/argo.pid" 2>/dev/null) >/dev/null 2>&1; then
        green "Argo隧道: 运行中 (PID: $(cat ${work_dir}/argo.pid))"
    else
        red "Argo隧道: 未运行"
    fi

    if ps -p $(cat "${work_dir}/http.pid" 2>/dev/null) >/dev/null 2>&1; then
        green "订阅服务: 运行中 (PID: $(cat ${work_dir}/http.pid))"
    else
        red "订阅服务: 未运行"
    fi
    echo ""
}

# 安装依赖（Alpine适配，提示apk命令）
check_dependencies() {
    green "=== 检查依赖 ===\n"
    local dependencies=("curl" "openssl" "jq" "python3" "base64" "ping" "procps-ng")  # [Alpine适配] 新增procps-ng
    local missing=()

    for dep in "${dependencies[@]}"; do
        if ! command_exists "$dep"; then
            missing+=("$dep")
        else
            green "$dep: 已安装"
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        red "缺少依赖: ${missing[*]}"
        # [Alpine适配] 改为apk add命令
        red "请联系管理员安装，或执行：sudo apk add ${missing[*]} (需sudo权限)\n"
        exit 1
    fi
    echo ""
}

# 主流程
main() {
    # 1. 检查依赖
    check_dependencies

    # 2. 停止残留进程
    stop_processes

    # 3. 安装sing-box
    install_singbox

    # 4. 启动所有进程
    start_processes

    # 5. 生成节点和订阅信息
    get_info

    # 6. 显示状态
    check_status

    # 7. 提示使用方法
    green "=== 使用说明 ===\n"
    green "1. 停止服务: ash $0 stop"  # [Alpine适配] 提示ash命令
    green "2. 重启服务: ash $0 restart"
    green "3. 查看状态: ash $0 status"
    green "4. 卸载脚本: ash $0 uninstall\n"
}

# 卸载脚本
uninstall() {
    stop_processes
    rm -rf "${work_dir}"
    green "已卸载：所有文件已删除\n"
    exit 0
}

# 重启argo（补充函数，避免报错）
restart_argo() {
    stop_processes
    nohup "${work_dir}/argo" tunnel --url http://localhost:8001 --no-autoupdate --edge-ip-version auto --protocol http2 > "${log_dir}/argo.log" 2>&1 &
    echo $! > "${work_dir}/argo.pid"
}

# 命令行参数处理（ash兼容）
case "$1" in
    "start")
        start_processes
        check_status
        ;;
    "stop")
        stop_processes
        green "已停止所有进程\n"
        ;;
    "restart")
        stop_processes
        start_processes
        check_status
        ;;
    "status")
        check_status
        ;;
    "uninstall")
        uninstall
        ;;
    *)
        main
        ;;
esac