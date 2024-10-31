#!/bin/bash

# 脚本保存路径
SCRIPT_PATH="$HOME/t3rn.sh"
LOGFILE="$HOME/executor/executor.log"
EXECUTOR_DIR="$HOME/executor"

# 样式定义
GREEN="\033[1;32m"
RED="\033[1;31m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
RESET="\033[0m"

# 检查是否以 root 用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}此脚本需要以 root 用户权限运行。${RESET}"
    echo -e "${YELLOW}请尝试使用 'sudo -i' 命令切换到 root 用户，然后再次运行此脚本。${RESET}"
    exit 1
fi

# 显示主菜单
function main_menu() {
    while true; do
        clear
        echo -e "${BLUE}==================================================${RESET}"
        echo -e "${GREEN}            欢迎使用 T3RN 节点管理工具           ${RESET}"
        echo -e "${BLUE}==================================================${RESET}"
        echo -e "${YELLOW}  作者：子清 ${RESET}"
        echo -e "${YELLOW}   X : https://x.com/qklxsqf  ▪️  TG : https://t.me/ksqxszq${RESET}"
        echo -e "${BLUE}==================================================${RESET}"
        echo -e "${GREEN} 1) ${RESET}${YELLOW}部署节点${RESET}"
        echo -e "${GREEN} 2) ${RESET}${YELLOW}查看日志${RESET}"
        echo -e "${GREEN} 3) ${RESET}${YELLOW}删除节点${RESET}"
        echo -e "${GREEN} 4) ${RESET}${YELLOW}重启节点${RESET}"
        echo -e "${GREEN} 5) ${RESET}${YELLOW}退出${RESET}"
        echo -e "${BLUE}==================================================${RESET}"
        
        read -p "请输入你的选择 [1-5]: " choice
        
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
                echo -e "${GREEN}退出脚本。${RESET}"
                exit 0
                ;;
            *)
                echo -e "${RED}无效的选择，请重新输入。${RESET}"
                ;;
        esac
    done
}

# 执行脚本函数
function execute_script() {
    if [ -d "$EXECUTOR_DIR" ]; then
        echo -e "${YELLOW}检测到节点服务已安装，跳过安装步骤。${RESET}"
    else
        # 下载文件
        echo -e "${BLUE}正在下载 executor-linux-v0.21.11.tar.gz...${RESET}"
        wget -q https://github.com/t3rn/executor-release/releases/download/v0.21.11/executor-linux-v0.21.11.tar.gz -O /tmp/executor-linux-v0.21.11.tar.gz
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}下载成功。${RESET}"
        else
            echo -e "${RED}下载失败，请检查网络连接或下载地址。${RESET}"
            return
        fi

        # 解压文件到 /tmp 目录
        echo -e "${BLUE}正在解压文件...${RESET}"
        tar -xzf /tmp/executor-linux-v0.21.11.tar.gz -C /tmp
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}解压成功。${RESET}"
        else
            echo -e "${RED}解压失败，请检查 tar.gz 文件。${RESET}"
            return
        fi

        # 显示解压后的目录内容
        echo -e "${BLUE}解压后的目录内容：${RESET}"
        ls -l /tmp

        # 检查解压后的目录并移动到 $EXECUTOR_DIR
        if [ -d "/tmp/executor" ]; then
            mv "/tmp/executor" "$EXECUTOR_DIR"
        elif [ -d "/tmp/executor-linux-v0.21.11" ]; then
            mv "/tmp/executor-linux-v0.21.11" "$EXECUTOR_DIR"
        else
            echo -e "${RED}未找到解压后的目录，可能文件名不正确。${RESET}"
            return
        fi

        # 删除压缩文件
        rm /tmp/executor-linux-v0.21.11.tar.gz
        echo -e "${GREEN}安装完成。${RESET}"
    fi

    # 设置环境变量
    export NODE_ENV=testnet
    export LOG_LEVEL=debug
    export LOG_PRETTY=false
    export ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,optimism-sepolia,l1rn'
    export EXECUTOR_PROCESS_ORDERS=true
    export EXECUTOR_PROCESS_CLAIMS=true
    export RPC_ENDPOINTS_OPSP='https://optimism-sepolia.blockpi.network/v1/rpc/public,https://api.zan.top/opt-sepolia'

    # 输入私钥
    read -p "请输入私钥: " PRIVATE_KEY_LOCAL
    export PRIVATE_KEY_LOCAL="$PRIVATE_KEY_LOCAL"

    # 切换目录并执行
    if [ -d "$EXECUTOR_DIR/bin" ]; then
        echo -e "${BLUE}切换目录并执行 ./executor...${RESET}"
        cd "$EXECUTOR_DIR/bin"
        ./executor > "$LOGFILE" 2>&1 &
        echo -e "${GREEN}executor 进程已启动，PID: $!${RESET}"
        echo -e "${GREEN}操作完成。${RESET}"
    else
        echo -e "${RED}未找到 bin 目录，检查解压后的文件结构。${RESET}"
        return
    fi

    # 提示用户按任意键返回主菜单
    read -n 1 -s -r -p "按任意键返回主菜单..."
}

# 重启节点函数
function restart_node() {
    echo -e "${BLUE}正在重启节点进程...${RESET}"
    pkill -f executor
    execute_script
}

# 查看日志函数
function view_logs() {
    if [ -f "$LOGFILE" ]; then
        echo -e "${BLUE}实时显示日志文件内容（按 Ctrl+C 退出）：${RESET}"
        tail -f "$LOGFILE"
    else
        echo -e "${YELLOW}日志文件不存在。${RESET}"
    fi
    read -n 1 -s -r -p "按任意键返回主菜单..."
}

# 删除节点函数
function delete_node() {
    echo -e "${BLUE}正在停止节点进程...${RESET}"
    pkill -f executor

    # 删除节点目录
    if [ -d "$EXECUTOR_DIR" ]; then
        echo -e "${BLUE}正在删除节点目录...${RESET}"
        rm -rf "$EXECUTOR_DIR"
        echo -e "${GREEN}节点目录已删除。${RESET}"
    else
        echo -e "${YELLOW}节点目录不存在，可能已被删除。${RESET}"
    fi
    read -n 1 -s -r -p "按任意键返回主菜单..."
}

# 启动主菜单
main_menu
