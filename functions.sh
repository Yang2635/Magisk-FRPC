#!/system/bin/sh
MODDIR=${0%/*}

# 用户可能的sdcard路径列表，一行一个
#external_storage_directory_arr=(
#/sdcard/
#/mnt/sdcard/
#/storage/emulated/0/
#/storage/self/primary/
#/mnt/user/0/self/primary/
#)

# toybox_cmd <cmd> [options]
toybox_cmd() {
  local toybox_bin_path='/system/bin/toybox'
  local toybox_bin="$(which toybox)"
  if [ -f "${toybox_bin_path}" ]; then
    ${toybox_bin_path} "$@"
  elif [ -n "${toybox_bin}" ]; then
    ${toybox_bin} "$@"
  else
    sed -i "/^description=/c description=使用Magisk挂载运行通用FRPC程序。[状态：未检测到toybox工具！]" "${MODDIR}/module.prop"
    exit 1
  fi
}

# get_parameters <key> <file>
get_parameters() {
  local REGEX="s/^$1[[:space:]]*=[[:space:]]*//p"
  shift
  local FILES=$@
  [ -z "${FILES}" ] && FILES="${MODDIR}/files/status.conf"
  sed -n "$REGEX" ${FILES} | head -n 1
}

# 检测获取frpc pid信息
# Detect and obtain frpc pid information
frpc_pid_check() {
  local frpc_pid
  if [ -f "${MODDIR}/files/frpc_run.pid" ]; then
    frpc_pid=$(cat ${MODDIR}/files/frpc_run.pid)
    echo "${frpc_pid}"
  else
    echo 0
  fi
}

# 获取frpc 进程
# Get frpc Process
process() {
  local f_arch=$(get_parameters F_ARCH)
  toybox_cmd ps -ef | grep "frpc-${f_arch}" | grep -v grep | wc -l
}

# frpc is running?
frpc_running_check() {
  local frpc_pid="$(frpc_pid_check)"
  local pidof_proc_pid="$(toybox_cmd pidof $1)"
  if [ "${frpc_pid}" -ne 0 ] && [ "$(process)" -eq 1 ]; then
    echo "${frpc_pid}"
  elif [ -n "${pidof_proc_pid}" ]; then
    echo "${pidof_proc_pid}"
  fi
}

# 获取frpc程序所用物理内存使用率
# Get the physical memory usage used by the frpc program
frpc_vmrss_check() {
  local frpc_pid="$(frpc_running_check $1)"
  if [ "${frpc_pid}" -ne 0 ]; then
    awk '/^VmRSS/{printf("%.2fMB",($2/1024))}' /proc/${frpc_pid}/status
  else
    echo "FRPC未运行！"
  fi
}

# 获取frpc程序使用的cpu使用率
# Get the cpu usage used by the frpc program
frpc_cpu_usage_check() {
  local frpc_pid="$(frpc_running_check $1)"
  if [ -n "${frpc_pid}" ]; then
    toybox_cmd ps --pid=${frpc_pid} -o pcpu | grep -v "CPU" | awk '{printf("%s%%",$1)}'
  else
    echo "无进程！"
  fi
}

# 获取电池是否正在充电的信息
# Get information about whether the battery is charging
battery_charge() {
  dumpsys battery | grep "powered" | grep 'true' | wc -l
}

# 获取当前电池电量信息
# Get current battery level information
battery_electricity() {
  dumpsys battery | awk '/level:([[:space:]]+)?/{print $2}'
}

# 获取设备当前运行的网络接口
# Get the network interface the device is currently running on
device_network_iface() {
  local route=$(sed '1d' /proc/net/route | awk '{printf("%s\n",$1)}' | xargs)
  if [ -n "${route}" ]; then
    echo $route
  fi
}

# 获取屏幕状态，“0”表示屏幕亮，“1”表示屏幕不亮
# Get the screen status, "0" means the screen is bright, "1" means the screen is not bright
screen_status() {
  dumpsys deviceidle | awk -F'=' '/mScreenOn/{print $2}' | sed -e 's/false/1/' -e 's/true/0/'
}
