#!/system/bin/sh
MODDIR=${0%/*}

# toybox_cmd <cmd> [options]
toybox_cmd() {
  local toybox_path
  toybox_path="$(which toybox)"
  [ -z "${toybox_path}" ] && exit 1
  ${toybox_path} "$@"
}

# 检测获取frpc pid信息
# Detect and obtain frpc pid information
frpc_pid_check() {
  local frpc_pid
  if [ -f ${MODDIR}/files/frpc_run.pid ]; then
    frpc_pid=$(cat ${MODDIR}/files/frpc_run.pid)
    echo "${frpc_pid}"
  else
    echo 0
  fi
}

# 获取frpc进程
# get frpc process
process() {
  toybox_cmd ps -ef | grep "frpc-${F_ARCH}" | grep -v grep | wc -l
}

# 获取frpc程序所用物理内存使用率
# Get the physical memory usage used by the frpc program
frpc_vmrss_check() {
  local FRPC_PID="$(frpc_pid_check)"
  if [ "${FRPC_PID}" -ne 0 ]; then
    awk '/^VmRSS/{printf("%.2fMB",($2/1024))}' /proc/${FRPC_PID}/status
  else
    echo "FRPC未运行！"
  fi
}

# 获取frpc程序使用的cpu使用率
# Get the cpu usage used by the frpc program
frpc_cpu_usage_check() {
  local FRPC_PID="$(frpc_pid_check)"
  if [ "${FRPC_PID}" -ne 0 ]; then
    toybox_cmd ps --pid=${FRPC_PID} -o pcpu | grep -v "CPU" | awk '{printf("%s%%",$1)}'
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
  dumpsys battery | awk '/level: /{print $2}'
}

# 获取屏幕状态，“0”表示屏幕亮，“1”表示屏幕不亮
# Get the screen status, "0" means the screen is bright, "1" means the screen is not bright
screen_status() {
  dumpsys deviceidle | awk -F'=' '/mScreenOn/{print $2}' | sed -e 's/false/1/' -e 's/true/0/'
}

# get_parameters <key> <file>
get_parameters() {
  local REGEX="s/^$1[[:space:]]*=[[:space:]]*//p"
  shift
  local FILES=$@
  [ -z "${FILES}" ] && FILES="${MODDIR}/files/status.conf"
  sed -n "$REGEX" ${FILES} | head -n 1
}
