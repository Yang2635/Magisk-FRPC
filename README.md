# Magisk-FRPC

A Magisk module for running FRPC on Android devices.

If your terminal device uses WEB service or other services need remote access, then this module will be your good choice.

---

在 Android 设备上运行 FRPC 的一个 Magisk 模块。

若您的终端设备使用了 WEB 服务或其他服务需要远程访问，那么该模块将是您的不错的选择。

## Usage

After the module is installed, please browse and edit the frpc.ini configuration file in the Android/frpc directory. Then restart the device, after the device is running, it will run the FRPC daemon on your device.

---

模块安装完成后，请到 Android/frpc 目录下浏览并编辑 frpc.ini 配置文件文件。然后重启设备，设备运行后，会在你的设备上运行 FRPC 守护程序。

## About

### Features

- The module supports `arm`, `arm64`, `amd64`, `x86` architecture. Automatically judge and apply the equipment instruction structure during installation.
- Use the crond command in the Busybox program carried by the module to establish the timing task detection status.
- After the FRPC configuration file is modified, it will automatically detect and reload the configuration file.
- Magisk module page automatically displays module status information.
- Check the integrity of the file to prevent the module from being damaged. (thanks to the inspiration provided by the Riru module).
- It can be turned on or off in the Magisk module to control the start and end of the FRPC program.
- The power of the device is less than 20% and the FRPC program is automatically terminated when it is not being charged. Please keep the device full of power!
- Creating a `screen` file in the module directory means that the screen is detected, otherwise it will not be detected.

---

- 模块支持`arm`、`arm64`、`amd64`、`x86`架构。安装时自动判断设备指令架构并应用。
- 使用模块携带的 Busybox 程序中 crond 命令建立定时任务检测状态。
- FRPC 配置文件修改后会自动检测并重载配置文件。
- Magisk 模块页面自动显示模块状态信息。
- 检验文件完整性，防止模块被破坏。（感谢 Riru 模块提供的灵感）。
- 可在 Magisk 模块中开启或关闭来控制 FRPC 程序启动与结束。
- 设备电量低于 20% 且未在充电自动终止 FRPC 程序，请保持设备电量充足！
- 在模块目录创建 `screen` 文件则表示息屏检测，反之不检测。

## How to build？

The traditional direct zip package construction method is not feasible, so I wrote a build script, you can refer to the article: https://www.isisy.com/1276.html

---

传统的直接打 zip 包构建方式已不可行，为此写了一份构建脚本，可参考文章：https://www.isisy.com/1276.html

## Uninstall && Clear

The module only releases the files required for additional work in the Android/frpc directory of the device (excluding other path settings for customizing frpc logs). If the `uninstall.sh` script is not executed when the module is uninstalled, please manually clear the files in the Android/frpc directory.

---

模块仅在设备 Android/frpc 目录释放额外工作需要的文件（不含 frpc 日志自定义其它路径设置），若模块卸载时未执行 `uninstall.sh` 脚本，请手动清除 Android/frpc 目录内文件。

> FRPC 程序的日志路径设置请勿设置到根目录中去，除非您有需要自定义日志路径，否则请保持默认日志设置或关闭日志生成。

## Thanks

- https://github.com/topjohnwu/Magisk
- https://github.com/osm0sis/android-busybox-ndk
- https://github.com/fatedier/frp
- https://github.com/RikkaApps/Riru
- 其它模块的参考
