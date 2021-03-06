# Magisk-FRPC
Use Magisk mount module to run FRPC.

If your terminal device uses WEB service or other services need remote access, then this module will be your good choice.

---

使用 Magisk 挂载模块运行 FRPC。

若您的终端设备使用了WEB服务或其他服务需要远程访问，那么该模块将是您的不错的选择。

## Usage

After the module is installed, please browse the frpc.ini file under the Android/frpc directory to read the relevant instructions and configuration files, and then restart the device. After the device is running, the FRPC daemon will run on your device.

---

模块安装完成后，请到 Android/frpc 目录下浏览 frpc.ini 文件阅读相关说明并配置文件，然后重启设备。设备运行后，会在你的设备运行FRPC守护程序。

## About

### Features

- The module supports `arm`, `arm64`, `amd64`, `x86` architecture. Automatically judge and apply the equipment instruction structure during installation.
- Use the crond command in the Busybox program carried by the module to establish the timing task detection status.
- After the FRPC configuration file is modified, it will automatically detect and reload the configuration file.
- Magisk module page automatically displays module status information.
- Check the integrity of the file to prevent the module from being damaged. (thanks to the inspiration provided by the Riru module).
- It can be turned on or off in the Magisk module to control the start and end of the FRPC program.
- The power of the device is less than 20% and the FRPC program is automatically terminated when it is not being charged. Please keep the device full of power!

---

- 模块支持`arm`、`arm64`、`amd64`、`x86`架构。安装时自动判断设备指令架构并应用。
- 使用模块携带的Busybox程序中crond命令建立定时任务检测状态。
- FRPC配置文件修改后会自动检测并重载配置文件。
- Magisk模块页面自动显示模块状态信息。
- 检验文件完整性，防止模块被破坏。（感谢Riru模块提供的灵感）。
- 可在Magisk模块中开启或关闭来控制FRPC程序启动与结束。
- 设备电量低于20%且未在充电自动终止FRPC程序，请保持设备电量充足！

## How to build？

The traditional direct zip package construction method is not feasible, so I wrote a build script, you can refer to the article: https://www.isisy.com/1276.html

---

传统的直接打zip包构建方式已不可行，为此写了一份构建脚本，可参考文章：https://www.isisy.com/1276.html

## Thanks

- https://github.com/topjohnwu/Magisk
- https://github.com/osm0sis/android-busybox-ndk
- https://github.com/fatedier/frp
- https://github.com/RikkaApps/Riru
- 其它模块的参考

