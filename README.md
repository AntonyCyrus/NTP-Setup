# NTP服务器配置脚本

这个脚本帮助您自动安装NTP服务，并配置多个全球范围内的NTP服务器。它还允许您选择时区。

## 功能

- 安装NTP服务。
- 添加多个全球范围内的NTP服务器。
- 使配置的NTP服务生效。
- 设置NTP服务开机自启动。
- 提供选择时区的功能。

## 使用前提

- 适用于基于Debian的Linux发行版（如Ubuntu）。
- 需要有Internet连接。
- 需要root用户权限。

## 安装和运行

要安装和配置NTP服务器，请运行以下命令：

```sh
wget https://raw.githubusercontent.com/AntonyCyrus/NTP-Setup/main/setup_ntp.sh
chmod +x setup_ntp.sh
sudo ./setup_ntp.sh

