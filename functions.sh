#!/system/bin/sh
#MODDIR=${0%/*}
MODDIR="$(dirname $(readlink -f "$0"))"

# 用户可能的sdcard路径列表，一行一个
#external_storage_directory_arr=(
#/sdcard/
#/mnt/sdcard/
#/storage/emulated/0/
#/storage/self/primary/
#/mnt/user/0/self/primary/
#)

# get_parameters <key> <file>
get_parameters() {
  local REGEX="s/^$1[[:space:]]*=[[:space:]]*//p"
  shift
  local FILES=$@
  [ -z "${FILES}" ] && FILES="${MODDIR}/files/status.conf"
  sed -n "$REGEX" ${FILES} | head -n 1
}


# 获取 frpc 进程数
# Get frpc Process number
process() {
  local _frpc_bin="$1"
  local _get_process_list
  _get_process_list=$(ps -ef | grep "${_frpc_bin}" | grep -v grep | awk '{print $1}' | xargs)
  if [ -n "${_get_process_list}" ]; then
    echo "${_get_process_list}"
  fi
}

# get frpc running pid
get_frpc_running_pid() {
  local _frpc_bin="$1"
  local _pidof_get_pid="$(pidof "${_frpc_bin}")"
  local _pidof_get_pid_number="$(echo "${_pidof_get_pid}" | wc -w)"
  local _get_process_pid="$(process ${_frpc_bin})"
  local _get_process_pid_number="$(echo "${_get_process_pid}" | wc -w)"
  local _frpc_pid=''
  local _get_exec_comm=''

  if [ -f "${MODDIR}/files/frpc_run.pid" ]; then
    _frpc_pid=$(cat ${MODDIR}/files/frpc_run.pid)

    if [ -n "${_frpc_pid}" ] && [ -d "/proc/${_frpc_pid}" ]; then
      _get_exec_comm="$(cat /proc/${_frpc_pid}/comm)"

      if [ "${_get_exec_comm}" == "${_frpc_bin}" ]; then
        if [ "${_pidof_get_pid_number}" -eq 1 ]; then
          echo "${_frpc_pid}"
          return
        fi
      fi
    fi
  fi

  if [ -n "${_pidof_get_pid}" ]; then
    echo "${_pidof_get_pid}"
    return
  fi

  if [ -n "${_get_process_pid}" ]; then
    echo "${_get_process_pid}"
    return
  else
    return 3
  fi
}

# 获取frpc程序所用物理内存使用率
# Get the physical memory usage used by the frpc program
frpc_vmrss_check() {
  local _frpc_bin="$1"
  local _frpc_pid="$(get_frpc_running_pid "${_frpc_bin}")"
  local _frpc_pid_num="$(echo "${_frpc_pid}" | wc -w)"
  if [ -n "${_frpc_pid}" ] && [ "${_frpc_pid_num}" -gt 1 ]; then
    echo "存在多个FRPC程序！"
    return 4
  fi
  if [ -n "${_frpc_pid}" ] && [ "${_frpc_pid_num}" -eq 1 ]; then
    awk '/^VmRSS/{printf("%.2fMB",($2/1024))}' /proc/${_frpc_pid}/status
  else
    echo "FRPC未运行！"
    return 5
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
  if [ -f "/proc/net/route" ]; then
    sed '1d' /proc/net/route | awk '{printf("%s\n",$1)}' | xargs
  fi
}

device_network_iface_number(){
  if [ -f "/proc/net/route" ]; then
    sed '1d' /proc/net/route | awk '{printf("%s\n",$1)}' | wc -l
  fi
}

# 获取屏幕状态，“0”表示屏幕亮，“1”表示屏幕不亮
# Get the screen status, "0" means the screen is bright, "1" means the screen is not bright
screen_status() {
  dumpsys deviceidle | awk -F'=' '/mScreenOn/{print $2}' | sed -e 's/false/1/' -e 's/true/0/'
}
