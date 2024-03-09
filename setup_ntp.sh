#!/bin/bash

# 定义NTP服务器数组
ntp_servers=(
    "0.pool.ntp.org"                 # 全球NTP服务器
    "1.pool.ntp.org"                 # 全球NTP服务器
    "2.pool.ntp.org"                 # 全球NTP服务器
    "3.pool.ntp.org"                 # 全球NTP服务器
    "debian.pool.ntp.org"            # Debian 默认NTP服务器
    "time.google.com"                # Google NTP服务器
    "time.windows.com"               # Windows NTP服务器
    "time.facebook.com"              # Facebook NTP服务器
    "time.cloudflare.com"            # Cloudflare NTP服务器
    "ntp1.aliyun.com"                # 阿里云中国大陆NTP服务器
    "ntp2.aliyun.com"                # 阿里云中国大陆NTP服务器
    "ntp3.aliyun.com"                # 阿里云中国大陆NTP服务器
    "ntp.ntsc.ac.cn"                 # 中国国家授时中心(NTSC)
    "cn.pool.ntp.org"                # 中国大陆NTP服务器
    "stdtime.gov.hk"                 # 香港NTP服务器
    "time.hko.hk"                    # 香港天文台(HKO)
    "time.stdtime.gov.tw"            # 台湾NTP服务器
    "clock.stdtime.gov.tw"           # 台湾国家标准时间与无线电实验室
    "sg.pool.ntp.org"                # 新加坡NTP服务器
    "ntp.nict.jp"                    # 日本NTP服务器
    "kr.pool.ntp.org"                # 韩国NTP服务器
    "time.bora.net"                  # BORA.net
    "ru.pool.ntp.org"                # 俄罗斯NTP服务器
    "ntp1.vniiftri.ru"               # 俄罗斯联邦科学研究所(VNIIFTRI)
    "ntp2.vniiftri.ru"               # 俄罗斯联邦科学研究所(VNIIFTRI)
    "time.iitb.ac.in"                # 印度理工学院孟买分校(Indian Institute of Technology Bombay)
    "in.pool.ntp.org"                # 印度NTP服务器
    "au.pool.ntp.org"                # 澳大利亚NTP服务器
    "ntp.ise.canberra.edu.au"        # 澳大利亚国立大学
    "us-west.pool.ntp.org"           # 美国西部NTP服务器
    "us-central.pool.ntp.org"        # 美国中部NTP服务器
    "us-east.pool.ntp.org"           # 美国东部NTP服务器
    "tick.usno.navy.mil"             # 美国海军天文台NTP服务器
    "tock.usno.navy.mil"             # 美国海军天文台NTP服务器
    "time.nist.gov"                  # 美国国家标准与技术研究院NTP服务器
    "uk.pool.ntp.org"                # 英国NTP服务器
    "ntp2d.mcc.ac.uk"                # 曼彻斯特大学
    "fr.pool.ntp.org"                # 法国NTP服务器
    "de.pool.ntp.org"                # 德国NTP服务器
    "ptbtime1.ptb.de"                # 德国物理技术联邦研究所
    "ptbtime2.ptb.de"                # 德国物理技术联邦研究所
    "asia.pool.ntp.org"              # 亚洲NTP服务器
    "europe.pool.ntp.org"            # 欧洲NTP服务器
    "north-america.pool.ntp.org"     # 北美NTP服务器
    "ar.pool.ntp.org"                # 阿根廷NTP服务器
    "br.pool.ntp.org"                # 巴西NTP服务器
    "co.pool.ntp.org"                # 哥伦比亚NTP服务器
    "eg.pool.ntp.org"                # 埃及NTP服务器
    "za.pool.ntp.org"                # 南非NTP服务器
    "ng.pool.ntp.org"                # 尼日利亚NTP服务器
    "ke.pool.ntp.org"                # 肯尼亚NTP服务器
    # 可以根据需要添加更多服务器
)


test_ntp_servers() {
    declare -A server_delay
    for server in "${ntp_servers[@]}"; do
        # 测试每个服务器的延迟
        delay=$(ntpdate -q "$server" 2>&1 | grep -Po 'offset \K[\d.]+ms' | head -1)
        if [ -n "$delay" ]; then
            server_delay[$server]=$delay
        else
            echo "服务器 $server 响应超时或无法访问"
        fi
    done

    # 按延迟排序并选择延迟最低的前十个服务器
    IFS=$'\n'
    sorted_servers=($(sort -n -k 2 <<<"${!server_delay[@]/%/ ${server_delay[@]}}"))
    unset IFS

    top_servers=("${sorted_servers[@]:0:10}")
    echo "选择的服务器: ${top_servers[*]}"
}
configure_ntp() {
    # 备份现有的ntp.conf文件
    if [ -f /etc/ntp.conf ]; then
        cp /etc/ntp.conf /etc/ntp.conf.backup
    fi

    # 创建新的ntp.conf文件
    echo "正在创建新的NTP配置文件..."
    > /etc/ntp.conf
    for server in "${ntp_servers[@]}"; do
        echo "server $server iburst" >> /etc/ntp.conf
    done

    # 安装NTP服务
    echo "正在检查并安装NTP服务..."
    apt-get update
    apt-get install -y ntp

    # 检查NTP服务状态并启动
    systemctl is-active --quiet ntp || systemctl start ntp

    # 设置NTP服务为开机自启
    systemctl enable ntp
    echo "NTP服务设置为开机自启。"

    # 用户交互: 是否立即强制NTP同步
    read -p "是否强制NTP立即同步？[Y/n]: " confirm
    confirm=${confirm:-Y}
    if [[ $confirm == [nN] ]]; then
        echo "跳过强制NTP同步。"
    else
        ntpd -gq
        echo "NTP同步完成。"

    # 显示所有NTP服务器信息
    echo "同步过程中使用的NTP服务器:"
    for server in "${ntp_servers[@]}"; do
        server_ip=$(getent hosts $server | awk '{print $1}')
        echo "- 服务器域名: $server
- 服务器IP: $server_ip"
    done

    
echo "脚本执行完毕。"
