#!/bin/sh

# 定义颜色
GREEN='\e[32m'
YELLOW='\e[33m'
RED='\e[31m'
RESET='\e[0m'

# 使用 getopts 解析命令行参数
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --file) IP_FILE="$2"; shift ;;
        --name) IPSET_NAME="$2"; shift ;;
        --action) ACTION="$2"; shift ;;
        *) echo -e "${RED}Unknown parameter passed: $1${RESET}"; exit 1 ;;
    esac
    shift
done

# 检查是否传入了必需的参数
if [ -z "$ACTION" ]; then
    echo -e "${YELLOW}Usage: $0 --action <add|delete|list> [--file <ip集合文件>] [--name <ip集合名称>]${RESET}"
    exit 1
fi

# 如果 action 是 list，则列出所有 ipset 集合名称
if [ "$ACTION" == "list" ]; then
    echo -e "${GREEN}Listing all ipset collections:${RESET}"
    ipset list -name
    exit 0
fi

# 如果 action 是 delete，则删除指定的 ipset 集合
if [ "$ACTION" == "delete" ]; then
    if [ -z "$IPSET_NAME" ]; then
        echo -e "${RED}Error: --name must be provided for deleting an ipset.${RESET}"
        exit 1
    fi

    echo -e "${YELLOW}Removing iptables/ip6tables rules associated with ipset: $IPSET_NAME${RESET}"
    
    # 先删除iptables和ip6tables中的相关规则
    iptables -D INPUT -m set --match-set $IPSET_NAME src -j DROP 2>/dev/null
    ip6tables -D INPUT -m set --match-set $IPSET_NAME src -j DROP 2>/dev/null

    # 删除ipset集合
    echo -e "${YELLOW}Deleting ipset collection: $IPSET_NAME${RESET}"
    ipset destroy $IPSET_NAME
    echo -e "${GREEN}Successfully deleted ipset collection: $IPSET_NAME${RESET}"
    exit 0
fi

# 如果 action 是 add，则添加 IP 到指定的 ipset 集合
if [ "$ACTION" == "add" ]; then
    # 检查是否提供了文件和集合名称
    if [ -z "$IP_FILE" ] || [ -z "$IPSET_NAME" ]; then
        echo -e "${RED}Error: --file and --name must be provided for adding IPs to ipset.${RESET}"
        exit 1
    fi

    # 检查ip集合文件是否存在
    if [ ! -f "$IP_FILE" ];then
        echo -e "${RED}Error: File $IP_FILE does not exist.${RESET}"
        exit 1
    fi

    # 创建IPv4和IPv6的ipset集合，使用不同的名称
    ipset create ${IPSET_NAME}_v4 hash:net family inet -exist
    ipset create ${IPSET_NAME}_v6 hash:net family inet6 -exist

    # 读取文件并处理IP地址
    while IFS= read -r line
    do
        if [[ $line == *:* ]]; then
            # 如果是IPv6地址
            ipset add ${IPSET_NAME}_v6 $line -exist
        else
            # 如果是IPv4地址
            ipset add ${IPSET_NAME}_v4 $line -exist
        fi
    done < "$IP_FILE"

    # 使用iptables屏蔽IPv4的ipset集合
    iptables -I INPUT -m set --match-set ${IPSET_NAME}_v4 src -j DROP
    # 使用ip6tables屏蔽IPv6的ipset集合
    ip6tables -I INPUT -m set --match-set ${IPSET_NAME}_v6 src -j DROP

    echo -e "${GREEN}IP addresses from $IP_FILE have been added to the ipset ${IPSET_NAME}_v4 (IPv4) and ${IPSET_NAME}_v6 (IPv6), and are now blocked.${RESET}"
    exit 0
fi

# 如果没有匹配到action，输出帮助信息
echo -e "${RED}Invalid action. Available actions are: add, delete, list.${RESET}"
exit 1
