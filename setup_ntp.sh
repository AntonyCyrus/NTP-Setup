#!/bin/bash

# 安装NTP服务
sudo apt-get update
sudo apt-get install -y ntp

# 定义NTP服务器数组（示例服务器，可根据需要修改）
ntp_servers=(
    # 全球
    "pool.ntp.org",
    
    # 中国大陆
    "ntp1.aliyun.com", "ntp2.aliyun.com", "ntp.ntsc.ac.cn", "cn.pool.ntp.org",
    
    # 香港
    "stdtime.gov.hk", "time.hko.hk",
    
    # 台湾
    "time.stdtime.gov.tw", "clock.stdtime.gov.tw",
    
    # 新加坡
    "time.nist.gov", "sg.pool.ntp.org",
    
    # 日本
    "ntp.nict.jp", "asia.pool.ntp.org",
    
    # 韩国
    "kr.pool.ntp.org", "time.bora.net",
    
    # 俄罗斯远东
    "ntp1.vniiftri.ru", "ntp2.vniiftri.ru",
    
    # 印度
    "time.iitb.ac.in", "in.pool.ntp.org",
    
    # 澳大利亚
    "au.pool.ntp.org", "ntp.ise.canberra.edu.au",
    
    # 美国西海岸
    "time-nw.nist.gov", "us-west.pool.ntp.org", "ntp-1.caltech.edu", "ntp-2.caltech.edu", "ntp-3.caltech.edu",
    
    # 美国东海岸
    "time-a.nist.gov", "time-b.nist.gov", "ntp.colorado.edu", "clock.uw.edu", "us-east.pool.ntp.org",
    
    # 英国
    "uk.pool.ntp.org",
    
    # 法国
    "fr.pool.ntp.org",
    
    # 德国
    "de.pool.ntp.org", "ptbtime1.ptb.de",
    
    # 其他欧洲地区
    "europe.pool.ntp.org",
    
    # 俄罗斯西部
    "ntp1.vniiftri.ru",
    
    # 北美洲
    "north-america.pool.ntp.org",
    
    # 美国海军天文台
    "tick.usno.navy.mil", "tock.usno.navy.mil"
)

# 备份原始的NTP配置文件
sudo cp /etc/ntp.conf /etc/ntp.conf.backup

# 清空配置文件中现有的NTP服务器
sudo sed -i '/^server /d' /etc/ntp.conf

# 添加NTP服务器到配置文件
for server in "${ntp_servers[@]}"; do
    echo "server $server" | sudo tee -a /etc/ntp.conf
done

# 重启NTP服务以使配置生效
sudo service ntp restart

# 设置NTP服务开机自启
sudo systemctl enable ntp

# 选择时区
echo "请选择时区（例如：Asia/Shanghai）:"
read timezone
sudo timedatectl set-timezone $timezone

echo "NTP服务器已设置并生效，时区已更新。"
