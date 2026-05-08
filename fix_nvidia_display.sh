 #!/bin/bash

# 检查是否为 root 权限
if [ "$EUID" -ne 0 ]; then 
  echo "请使用 sudo 运行此脚本: sudo bash $0"
  exit 1
fi

echo "--- 开始执行 NVIDIA 显示优化脚本 ---"

# 1. 安装 NVIDIA 535 驱动 (针对 Mint/Pop!_OS/Ubuntu)
if command -v apt &> /dev/null; then
    echo "检测到 Debian 系系统，正在安装 nvidia-driver-535..."
    apt update
    apt install -y nvidia-driver-535
else
    echo "非 APT 系统，请手动确保已安装 nvidia-driver-535 或对应版本。"
fi

# 2. 修改 /etc/systemd/logind.conf 以忽略合盖动作
echo "正在配置 logind.conf 以忽略合盖动作..."
CONF="/etc/systemd/logind.conf"
# 移除原有相关配置的注释并修改值为 ignore
sed -i 's/^#\(HandleLidSwitch=\).*/\1ignore/' $CONF
sed -i 's/^#\(HandleLidSwitchExternalPower=\).*/\1ignore/' $CONF
sed -i 's/^#\(HandleLidSwitchDocked=\).*/\1ignore/' $CONF
# 确保即使没有注释也被修改
sed -i 's/^\(HandleLidSwitch=\).*/\1ignore/' $CONF
sed -i 's/^\(HandleLidSwitchExternalPower=\).*/\1ignore/' $CONF
sed -i 's/^\(HandleLidSwitchDocked=\).*/\1ignore/' $CONF

# 3. 修改 GRUB 启用 nvidia-drm.modeset=1
echo "正在配置 GRUB 开启 modeset..."
GRUB_FILE="/etc/default/grub"
if grep -q "nvidia-drm.modeset=1" "$GRUB_FILE"; then
    echo "GRUB 已包含 nvidia-drm.modeset=1，跳过。"
else
    # 在 quiet splash 后面添加参数
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia-drm.modeset=1 /' $GRUB_FILE
fi

# 4. 更新 GRUB 配置
echo "正在更新 GRUB 配置..."
if command -v update-grub &> /dev/null; then
    update-grub
elif [ -f /boot/grub2/grub.cfg ]; then
    grub2-mkconfig -o /boot/grub2/grub.cfg
elif [ -f /boot/efi/EFI/fedora/grub.cfg ]; then
    grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
fi

# 5. 重启 logind 服务
systemctl restart systemd-logind

echo "--- 设置完成！ ---"
echo "请手动重启电脑以应用 GRUB 和驱动更改。"