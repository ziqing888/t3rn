#!/bin/bash

# 脚本路径和日志文件路径
SCRIPT_PATH="$HOME/t3rn.sh"
LOGFILE="$HOME/executor/executor.log"
EXECUTOR_DIR="$HOME/executor"

# 样式变量定义
GREEN="\033[1;32m"
RED="\033[1;31m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
RESET="\033[0m"

# 信息图标
INFO_ICON="${BLUE}ℹ️${RESET}"
SUCCESS_ICON="${GREEN}✔️${RESET}"
ERROR_ICON="${RED}❌${RESET}"
WARNING_ICON="${YELLOW}⚠️${RESET}"

# 权限检查
if [ "$(id -u)" != "0" ]; then
    echo -e "${ERROR_ICON} 此脚本需要 root 权限运行。"
    echo -e "${INFO_ICON} 请使用 'sudo -i' 切换到 root 用户后重新运行。"
    exit 1
fi

# 信息显示函数
function display_message() {
    local type="$1"
    local message="$2"
    case "$type" in
        info) echo -e "${INFO_ICON} ${message}" ;;
        success) echo -e "${SUCCESS_ICON} ${message}" ;;
        error) echo -e "${ERROR_ICON} ${message}" ;;
        warning) echo -e "${WARNING_ICON} ${message}" ;;
        *) echo "$message" ;;
    esac
}

# 主菜单函数
function main_menu() {
    while true; do
        clear
        echo -e "${BLUE}======= Node 管理工具 =======${RESET}"
        echo -e "${GREEN}版本：v1.0.0${RESET}"
        echo -e "${GREEN}开发者：大赌社区${RESET}"
        echo "================================"
        echo "1) 初始化节点"
        echo "2) 查看运行日志"
        echo "3) 删除节点服务"
        echo "4) 重启节点服务"
        echo "5) 退出"
        echo "================================"

        read -p "请输入选项 [1-5]: " choice

        case $choice in
            1) initialize_node ;;
            2) view_log_file ;;
            3) remove_node_service ;;
            4) restart_node_service ;;
            5) display_message "success" "退出工具"; exit 0 ;;
            *) display_message "error" "无效选项，请重新输入。" ;;
        esac
    done
}

# 初始化节点服务
function initialize_node() {
    # 检查是否已经安装
    if [ -d "$EXECUTOR_DIR" ]; then
        display_message "warning" "检测到节点服务已安装，跳过安装步骤。"
    else
        # 如果未安装则下载并解压
        display_message "info" "正在下载节点文件..."
        wget -q https://github.com/t3rn/executor-release/releases/download/v0.21.11/executor-linux-v0.21.11.tar.gz -O /tmp/node_package.tar.gz

        if [ $? -ne 0 ]; then
            display_message "error" "下载失败，请检查网络连接。"
            return
        fi

        display_message "info" "解压安装包..."
        tar -xzf /tmp/node_package.tar.gz -C ~/
        mv ~/executor-linux-v0.21.11 "$EXECUTOR_DIR" || exit 1

        display_message "success" "安装成功。"
    fi

    # 配置环境并启动节点
    display_message "info" "配置环境并启动节点服务..."
    configure_environment
    cd "$EXECUTOR_DIR/bin" || exit
    ./executor > "$LOGFILE" 2>&1 &
    display_message "success" "节点服务已启动，PID: $!"
    pause_to_menu
}

# 环境变量配置
function configure_environment() {
    export NODE_ENV=testnet
    export LOG_LEVEL=debug
    export LOG_PRETTY=false
    export ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,optimism-sepolia,l1rn'
    export EXECUTOR_PROCESS_ORDERS=true
    export EXECUTOR_PROCESS_CLAIMS=true
    export RPC_ENDPOINTS_OPSP='https://optimism-sepolia.blockpi.network/v1/rpc/public,https://api.zan.top/opt-sepolia'
    read -p "请输入您的私钥: " PRIVATE_KEY_LOCAL
    export PRIVATE_KEY_LOCAL="$PRIVATE_KEY_LOCAL"
    display_message "success" "环境变量配置完成。"
}

# 查看日志
function view_log_file() {
    if [ -f "$LOGFILE" ]; then
        display_message "info" "显示日志（Ctrl+C 返回主菜单）："
        tail -f "$LOGFILE"
    else
        display_message "warning" "日志文件不存在。"
    fi
    pause_to_menu
}

# 删除节点服务
function remove_node_service() {
    display_message "info" "停止节点服务..."
    pkill -f executor

    display_message "info" "删除节点目录..."
    rm -rf "$EXECUTOR_DIR"
    display_message "success" "节点服务删除完成。"
    pause_to_menu
}

# 重启节点服务
function restart_node_service() {
    display_message "info" "重启节点服务..."
    pkill -f executor
    initialize_node
}

# 暂停并返回菜单
function pause_to_menu() {
    read -n 1 -s -r -p "按任意键返回主菜单..."
    main_menu
}

# 启动主菜单
main_menu
