#!/bin/bash

# 定义NTP服务器数组
ntp_servers=(
    "debian.pool.ntp.org",            # Debian 默认NTP服务器
    "time.google.com",                # Google NTP服务器
    "time.windows.com",               # Windows NTP服务器
    "time.facebook.com",              # Facebook NTP服务器
    "pool.ntp.org",                   # 全球NTP服务器
    "ntp1.aliyun.com",                # 阿里云中国大陆NTP服务器
    "ntp2.aliyun.com",
    "ntp3.aliyun.com",
    "ntp.ntsc.ac.cn",                 # 中国国家授时中心(NTSC)
    "cn.pool.ntp.org",                # 中国大陆NTP服务器
    "stdtime.gov.hk",                 # 香港NTP服务器
    "time.hko.hk",                    # 香港天文台(HKO)
    "time.stdtime.gov.tw",            # 台湾NTP服务器
    "clock.stdtime.gov.tw",           # 台湾国家标准时间与无线电实验室
    "sg.pool.ntp.org",                # 新加坡NTP服务器
    "ntp.nict.jp",                    # 日本NTP服务器
    "kr.pool.ntp.org",                # 韩国NTP服务器
    "time.bora.net",                  # BORA.net
    "ru.pool.ntp.org",                # 俄罗斯NTP服务器
    "ntp1.vniiftri.ru",               # 俄罗斯联邦科学研究所(VNIIFTRI)
    "ntp2.vniiftri.ru",
    "time.iitb.ac.in",                # 印度理工学院孟买分校(Indian Institute of Technology Bombay)
    "in.pool.ntp.org",                # 印度NTP服务器
    "au.pool.ntp.org",                # 澳大利亚NTP服务器
    "ntp.ise.canberra.edu.au",        # 澳大利亚国立大学
    "us-west.pool.ntp.org",           # 美国西部NTP服务器
    "us-central.pool.ntp.org",        # 美国中部NTP服务器
    "us-east.pool.ntp.org",           # 美国东部NTP服务器
    "tick.usno.navy.mil",             # 美国海军天文台NTP服务器
    "tock.usno.navy.mil",
    "time.nist.gov",                  # 美国国家标准与技术研究院NTP服务器
    "uk.pool.ntp.org",                # 英国NTP服务器
    "ntp2d.mcc.ac.uk",                # 曼彻斯特大学
    "fr.pool.ntp.org",                # 法国NTP服务器
    "de.pool.ntp.org",                # 德国NTP服务器
    "ptbtime1.ptb.de",                # 德国物理技术联邦研究所
    "ptbtime2.ptb.de",
    "asia.pool.ntp.org",              # 亚洲NTP服务器
    "europe.pool.ntp.org",            # 欧洲NTP服务器
    "north-america.pool.ntp.org",     # 北美NTP服务器
    "south-america.pool.ntp.org",     # 南美NTP服务器
    "africa.pool.ntp.org",            # 非洲NTP服务器
    "oceania.pool.ntp.org"            # 大洋洲NTP服务器
)

# 检查是否以root用户执行
if [ "$(id -u)" != "0" ]; then
    echo "请以root用户运行此脚本。"
    exit 1
fi

test_ntp_servers() {
    local server_delay
    local server_responses=()
    local max_servers=10  # Maximum number of servers to select

    echo "正在测试NTP服务器的响应时间..."
    for server in "${ntp_servers[@]}"; do
        sleep 1
        # Testing each server's response time using ntpdate -q
        server_delay=$(ntpdate -q $server 2>&1 | grep 'offset' | awk '{print $6}')
        
        # Check if the response was successful and add to the list if so
        if [[ ! -z "$server_delay" ]]; then
            server_responses+=("$server $server_delay")
        fi
    done

    # Sort servers by response time and pick the top ones
    IFS=$'\\n' top_servers=($(sort -k2 -n <<<"${server_responses[*]}" | head -n $max_servers))
    unset IFS

    # Extract just the server names to use in configuration
    ntp_servers=()
    echo "选择的NTP服务器:"
    for entry in "${top_servers[@]}"; do
        server=$(echo "$entry" | awk '{print $1}')
        ntp_servers+=("$server")
        echo "$server"
    done
}

configure_ntp() {
    # Test and select the best NTP servers
    test_ntp_servers

    # Install NTP service
    apt-get update && apt-get install -y ntp || { echo "安装NTP失败"; exit 1; }

    # Backup the original NTP configuration file
    cp /etc/ntp.conf /etc/ntp.conf.backup || { echo "备份NTP配置失败"; exit 1; }

    # Clear existing NTP servers in the configuration file
    sed -i '/^server /d' /etc/ntp.conf

    # Add NTP servers to the configuration file
    for server in "${ntp_servers[@]}"; do
        echo "server $server iburst" >> /etc/ntp.conf
    done

    # User interaction: Whether to restart NTP service
    read -p "是否重启NTP服务以使配置生效？[Y/n]: " confirm
    confirm=${confirm:-Y}
    if [[ $confirm == [nN] ]]; then
        echo "跳过重启NTP服务。"
    else
        systemctl restart ntp
        echo "NTP服务已重启。"
    fi

    # User interaction: Whether to set NTP service to start on boot
    read -p "是否设置NTP服务开机自启？[Y/n]: " confirm
    confirm=${confirm:-Y}
    if [[ $confirm == [nN] ]]; then
        echo "跳过设置NTP服务开机自启。"
    else
        systemctl enable ntp
        echo "NTP服务设置为开机自启。"
    fi

    # User interaction: Whether to force immediate NTP synchronization
    read -p "是否强制NTP立即同步？[Y/n]: " confirm
    confirm=${confirm:-Y}
    if [[ $confirm == [nN] ]]; then
        echo "跳过强制NTP同步。"
    else
        ntpd -gq
        echo "NTP同步完成。"
    fi

    # User interaction: Whether to display NTP synchronization status
    read -p "是否显示NTP同步状态？[Y/n]: " confirm
    confirm=${confirm:-Y}
    if [[ $confirm == [nN] ]]; then
        echo "跳过显示NTP同步状态。"
    else
        ntpq -p
    fi
}

change_timezone() {
    # Select timezone
    echo "请选择时区（例如：Asia/Shanghai）:"
    read timezone
    timedatectl set-timezone "$timezone" || { echo "更改时区失败"; exit 1; }

    # Display system time
    timedatectl

    # Display the current system time
    date
}

uninstall_ntp() {
    # Confirm whether to continue uninstallation
    read -p "您确定要卸载NTP服务吗？[y/N]: " confirm
    confirm=${confirm:-N}
    if [[ $confirm != [yY] ]]; then
        echo "取消卸载。"
        return
    fi

    # Stop the NTP service
    systemctl stop ntp

    # Uninstall the NTP service
    apt-get remove --purge -y ntp || { echo "卸载NTP失败"; exit 1; }

    # Restore the original ntp configuration file
    if [ -f /etc/ntp.conf.backup ]; then
        mv /etc/ntp.conf.backup /etc/ntp.conf
    fi

    # Restart the system time service
    systemctl restart systemd-timesyncd.service
    echo "NTP服务已卸载，原始配置已还原。"
}

# Main menu
while true; do
    echo "请选择一个选项:"
    echo "1) 配置添加NTP服务器并保存并开机自启"
    echo "2) 更改系统时区"
    echo "3) 卸载NTP服务并还原配置"
    echo "4) 退出"
    read -p "输入选项 [1-4]: " option

    case $option in
        1)
            configure_ntp
            ;;
        2)
            change_timezone
            ;;
        3)
            uninstall_ntp
            ;;
        4)
            break
            ;;
        *)
            echo "无效选项，请重新选择。"
            ;;
    esac
done

echo "脚本执行完毕。"
