#!/bin/bash

# 安装NTP服务
sudo apt-get update
sudo apt-get install -y ntp

# 定义NTP服务器数组（示例服务器，可根据需要修改）
# ...（其他服务器配置保持不变）

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

# 强制NTP立即同步
sudo ntpd -gq

# 显示NTP同步状态
ntpq -p

# 验证NTP服务是否生效
echo "正在检查NTP服务状态..."
sudo systemctl status ntp

# 显示一个简单的确认消息，提示用户NTP同步是否成功
if timedatectl status | grep "NTP synchronized: yes"; then
    echo "NTP服务已成功同步。"
else
    echo "NTP服务同步失败，请检查您的NTP配置和网络连接。"
fi

echo "NTP服务器已设置并生效，时区已更新。"
