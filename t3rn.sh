#!/bin/bash

# 样式变量定义
GREEN="\033[1;32m"
RED="\033[1;31m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
RESET="\033[0m"

# 信息图标
INFO_ICON="${BLUE}ℹ${RESET}"
SUCCESS_ICON="${GREEN}✔${RESET}"
ERROR_ICON="${RED}❌${RESET}"
WARNING_ICON="${YELLOW}⚠${RESET}"

# 脚本保存路径
SCRIPT_PATH="$HOME/t3rn.sh"
LOGFILE="$HOME/executor/executor.log"
EXECUTOR_DIR="$HOME/executor"

# 检查是否以 root 用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo -e "${ERROR_ICON} 此脚本需要以 root 用户权限运行。"
    echo -e "${INFO_ICON} 请尝试使用 'sudo -i' 命令切换到 root 用户，然后再次运行此脚本。"
    exit 1
fi

# 主菜单函数
function main_menu() {
    while true; do
        clear
        echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════╗${RESET}"
        echo -e "${BLUE}║${RESET}          ${GREEN} t3rn 节点管理工具${RESET}            ${BLUE}║${RESET}"
        echo -e "${BLUE}║${RESET}                                                              ║${RESET}"
        echo -e "${BLUE}╠══════════════════════════════════════════════════════════════════════╣${RESET}"
        echo -e "${BLUE}║${RESET} ${INFO_ICON} ${YELLOW}请选择要执行的操作:${RESET}       ${BLUE}║${RESET}"
        echo -e "${BLUE}║${RESET}  1) 部署节点                                           ${BLUE}║${RESET}"
        echo -e "${BLUE}║${RESET}  2) 查看日志                                           ${BLUE}║${RESET}"
        echo -e "${BLUE}║${RESET}  3) 删除节点                                           ${BLUE}║${RESET}"
        echo -e "${BLUE}║${RESET}  4) 重启节点                                           ${BLUE}║${RESET}"
        echo -e "${BLUE}║${RESET}  5) 退出                                               ${BLUE}║${RESET}"
        echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════╝${RESET}"

        read -p "$(echo -e "${YELLOW}请输入你的选择 [1-5]: ${RESET}")" choice

        case $choice in
            1)
                execute_script
                ;;
            2)
                view_logs
                ;;
            3)
                delete_node
                ;;
            4)
                restart_node
                ;;
            5)
                echo -e "${SUCCESS_ICON} 退出脚本。"
                exit 0
                ;;
            *)
                echo -e "${ERROR_ICON} 无效的选择，请重新输入。"
                ;;
        esac
    done
}

# 重启节点函数
function restart_node() {
    echo -e "${INFO_ICON} 正在重启节点进程..."

    pkill -f executor

    echo -e "${INFO_ICON} 切换目录并执行 ./executor..."
    cd ~/executor/executor/bin || { echo -e "${ERROR_ICON} 目录不存在。"; return; }

    export NODE_ENV=testnet
    export LOG_LEVEL=debug
    export LOG_PRETTY=false
    export ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,optimism-sepolia,l1rn'

    export EXECUTOR_PROCESS_ORDERS=true
    export EXECUTOR_PROCESS_CLAIMS=true
    export RPC_ENDPOINTS_OPSP='https://optimism-sepolia.blockpi.network/v1/rpc/public,https://api.zan.top/opt-sepolia'

    read -p "输入私钥: " PRIVATE_KEY_LOCAL
    export PRIVATE_KEY_LOCAL="$PRIVATE_KEY_LOCAL"

    ./executor > "$LOGFILE" 2>&1 &

    echo -e "${SUCCESS_ICON} executor 进程已重启，PID: $!"

    echo -e "${SUCCESS_ICON} 重启操作完成。"

    read -n 1 -s -r -p "按任意键返回主菜单..."
    main_menu
}

# 执行脚本函数
function execute_script() {
    echo -e "${INFO_ICON} 正在下载 executor-linux-v0.21.11.tar.gz..."
    wget https://github.com/t3rn/executor-release/releases/download/v0.21.11/executor-linux-v0.21.11.tar.gz

    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS_ICON} 下载成功。"
    else
        echo -e "${ERROR_ICON} 下载失败，请检查网络连接或下载地址。"
        exit 1
    fi

    echo -e "${INFO_ICON} 正在解压文件..."
    tar -xvzf executor-linux-v0.21.11.tar.gz

    if [ $? -eq 0 ]; then
        echo -e "${SUCCESS_ICON} 解压成功。"
    else
        echo -e "${ERROR_ICON} 解压失败，请检查 tar.gz 文件。"
        exit 1
    fi

    echo -e "${INFO_ICON} 正在检查解压后的文件或目录名称是否包含 'executor'..."
    if ls | grep -q 'executor'; then
        echo -e "${SUCCESS_ICON} 检查通过，找到包含 'executor' 的文件或目录。"
    else
        echo -e "${WARNING_ICON} 未找到包含 'executor' 的文件或目录，可能文件名不正确。"
        exit 1
    fi

    export NODE_ENV=testnet
    export LOG_LEVEL=debug
    export LOG_PRETTY=false
    export ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,optimism-sepolia,l1rn'

    export EXECUTOR_PROCESS_ORDERS=true
    export EXECUTOR_PROCESS_CLAIMS=true
    export RPC_ENDPOINTS_OPSP='https://optimism-sepolia.blockpi.network/v1/rpc/public,https://api.zan.top/opt-sepolia'

    read -p "请输入 PRIVATE_KEY_LOCAL 的值: " PRIVATE_KEY_LOCAL
    export PRIVATE_KEY_LOCAL="$PRIVATE_KEY_LOCAL"

    echo -e "${INFO_ICON} 删除压缩包..."
    rm executor-linux-v0.21.11.tar.gz

    echo -e "${INFO_ICON} 切换目录并执行 ./executor..."
    cd ~/executor/executor/bin || { echo -e "${ERROR_ICON} 目录不存在。"; return; }

    ./executor > "$LOGFILE" 2>&1 &

    echo -e "${SUCCESS_ICON} executor 进程已启动，PID: $!"

    echo -e "${SUCCESS_ICON} 操作完成。"

    read -n 1 -s -r -p "按任意键返回主菜单..."
    main_menu
}

# 查看日志函数
function view_logs() {
    if [ -f "$LOGFILE" ]; then
        echo -e "${INFO_ICON} 实时显示日志文件内容（按 Ctrl+C 退出）："
        tail -f "$LOGFILE"
    else
        echo -e "${WARNING_ICON} 日志文件不存在。"
    fi
}

# 删除节点函数
function delete_node() {
    echo -e "${INFO_ICON} 正在停止节点进程..."

    pkill -f executor

    if [ -d "$EXECUTOR_DIR" ]; then
        echo -e "${INFO_ICON} 正在删除节点目录..."
        rm -rf "$EXECUTOR_DIR"
        echo -e "${SUCCESS_ICON} 节点目录已删除。"
    else
        echo -e "${WARNING_ICON} 节点目录不存在，可能已被删除。"
    fi

    echo -e "${SUCCESS_ICON} 节点删除操作完成。"

    read -n 1 -s -r -p "按任意键返回主菜单..."
    main_menu
}

# 启动主菜单
main_menu

