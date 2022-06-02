#!/system/bin/sh

MODDIR=${0%/*}
. ${MODDIR}/files/status.conf
. ${MODDIR}/functions.sh
Busybox_file="${MODDIR}/files/bin/busybox_${F_ARCH}"

if [ ! -s "${MODDIR}/module.prop" ]; then
  cp -af "${MODDIR}/files/module.prop.bak" "${MODDIR}/module.prop"
fi

runing_start() {
  local frpc_admin_prot
  if [ -f "${DATADIR}/frpc/frpc.ini" ]; then
    sed -i "/^FILE_STATUS=/c FILE_STATUS=$(stat -c %Y ${DATADIR}/frpc/frpc.ini)" "${MODDIR}/files/status.conf"
    sh ${MODDIR}/Run_FRPC.sh verify
    if [ "$?" -eq 0 ]; then
      sed -i "/^CHECK_FILE_STATUS=/c CHECK_FILE_STATUS=配置文件检测正确！" "${MODDIR}/files/status.conf"
      sh ${MODDIR}/Run_FRPC.sh start
      sleep 5
      if [ "$(frpc_pid_check)" -ne 0 ]; then
        frpc_admin_prot=$(get_parameters admin_port "${DATADIR}/frpc/frpc.ini")
        if [ "${frpc_admin_prot}" -ge 1 ] && [ "${frpc_admin_prot}" -le 65535 ]; then
          running_num=$(sh ${MODDIR}/Run_FRPC.sh status)
          sed -i -e "/^RUNNING_STATUS=/c RUNNING_STATUS=FRPC正在运行中！" \
            -e "/^RELOAD_NUM=/c RELOAD_NUM=0" -e "/^RUNNING_NUM=/c RUNNING_NUM=${running_num}" "${MODDIR}/files/status.conf"
        elif [ -z "${frpc_admin_prot}" ]; then
          sed -i -e "/^RUNNING_STATUS=/c RUNNING_STATUS=FRPC正在运行中！" \
            -e "/^RELOAD_NUM=/c RELOAD_NUM=0" -e "/^RUNNING_NUM=/c RUNNING_NUM=未定义端口！" "${MODDIR}/files/status.conf"
        fi
      elif [ "$(process)" -ne 0 ]; then
        frpc_admin_prot=$(get_parameters admin_port "${DATADIR}/frpc/frpc.ini")
        if [ "${frpc_admin_prot}" -ge 1 ] && [ "${frpc_admin_prot}" -le 65535 ]; then
          running_num=$(sh ${MODDIR}/Run_FRPC.sh status)
          sed -i -e "/^RUNNING_STATUS=/c RUNNING_STATUS=FRPC正在运行中（无pid文件）！" \
            -e "/^RELOAD_NUM=/c RELOAD_NUM=0" -e "/^RUNNING_NUM=/c RUNNING_NUM=${running_num}" "${MODDIR}/files/status.conf"
        elif [ -z "${frpc_admin_prot}" ]; then
          sed -i -e "/^RUNNING_STATUS=/c RUNNING_STATUS=FRPC正在运行中（无pid文件）！" \
            -e "/^RELOAD_NUM=/c RELOAD_NUM=0" -e "/^RUNNING_NUM=/c RUNNING_NUM=未定义端口！" "${MODDIR}/files/status.conf"
        fi
      else
        sed -i "/^RUNNING_STATUS=/c RUNNING_STATUS=FRPC启动失败！" "${MODDIR}/files/status.conf"
      fi
    else
      sed -i -e "/^CHECK_FILE_STATUS=/c CHECK_FILE_STATUS=配置文件检测错误，请自查配置文件！" \
        -e "/^RUNNING_STATUS=/c RUNNING_STATUS=FRPC未运行！" "${MODDIR}/files/status.conf"
    fi
  else
    sed -i -e "/^CHECK_FILE_STATUS=/c CHECK_FILE_STATUS=Android\/frpc目录下未找到frpc\.ini文件！" \
      -e "/^RUNNING_STATUS=/c RUNNING_STATUS=FRPC未运行！" "${MODDIR}/files/status.conf"
  fi
}

check_reload() {
  if [ -f ${DATADIR}/frpc/frpc.ini ]; then
    check_new_file_status="$(stat -c %Y ${DATADIR}/frpc/frpc.ini)"
    if [ "${FILE_STATUS}" != "${check_new_file_status}" ]; then
      sh ${MODDIR}/Run_FRPC.sh verify
      if [ "$?" -eq 0 ]; then
        sh ${MODDIR}/Run_FRPC.sh reload
        if [ "$?" -eq 0 ]; then
          sleep 2
          frpc_admin_prot=$(get_parameters admin_port "${DATADIR}/frpc/frpc.ini")
          if [ "${frpc_admin_prot}" -ge 1 ] && [ "${frpc_admin_prot}" -le 65535 ]; then
            running_num=$(sh ${MODDIR}/Run_FRPC.sh status)
            sed -i -e "/^RELOAD_NUM=/c RELOAD_NUM=$(($RELOAD_NUM + 1))" -e "/^FILE_STATUS=/c FILE_STATUS=${check_new_file_status}" \
              -e "/^CHECK_FILE_STATUS=/c CHECK_FILE_STATUS=配置文件检测正确！" \
              -e "/^RUNNING_NUM=/c RUNNING_NUM=${running_num}" "${MODDIR}/files/status.conf"
          elif [ -z "${frpc_admin_port}" ]; then
            sed -i -e "/^RELOAD_NUM=/c RELOAD_NUM=$(($RELOAD_NUM + 1))" -e "/^FILE_STATUS=/c FILE_STATUS=${check_new_file_status}" \
              -e "/^CHECK_FILE_STATUS=/c CHECK_FILE_STATUS=配置文件检测正确！" \
              -e "/^RUNNING_NUM=/c RUNNING_NUM=未定义端口！" "${MODDIR}/files/status.conf"
          fi
        else
          sed -i "/^CHECK_FILE_STATUS=/c CHECK_FILE_STATUS=配置文件检测正确但重载失败，请自查配置文件或重启frpc程序！（已保持当前运行状态）" "${MODDIR}/files/status.conf"
        fi
      else
        sed -i "/^CHECK_FILE_STATUS=/c CHECK_FILE_STATUS=配置文件检测错误，请自查配置文件！（已保持当前运行状态）" "${MODDIR}/files/status.conf"
      fi
    fi
  else
    sed -i "/^CHECK_FILE_STATUS=/c CHECK_FILE_STATUS=Android\/frpc目录下未找到frpc\.ini文件！（已保持当前运行状态）" "${MODDIR}/files/status.conf"
  fi
}

main() {
  local FRPC_CPU_Usage FRPC_VmRSS
  if [ "$(battery_electricity)" -lt 20 ] && [ "$(battery_charge)" -eq 0 ]; then
    if [ "$(frpc_pid_check)" -ne 0 ]; then
      {
        kill -9 "$(frpc_pid_check)"
        rm -f "${MODDIR}/files/frpc_run.pid"
      }
      if [ "$?" -eq 0 ]; then
        sed -i -e "/^CHECK_FILE_STATUS=/c CHECK_FILE_STATUS=已自动停止检测！" \
          -e "/^RUNNING_STATUS=/c RUNNING_STATUS=当前电量低于20%且未在充电，自动停止运行！" \
          -e "/^RUNNING_NUM=/c RUNNING_NUM=已自动停止检测！" "${MODDIR}/files/status.conf"
      fi
    elif [ "$(process)" -ne 0 ]; then
      { kill -9 "$(ps -ef | grep "frpc-${F_ARCH}" | grep -v grep | awk '{ print $2 }')"; }
      if [ "$?" -eq 0 ]; then
        sed -i -e "/^CHECK_FILE_STATUS=/c CHECK_FILE_STATUS=已自动停止检测！" \
          -e "/^RUNNING_STATUS=/c RUNNING_STATUS=当前电量低于20%且未在充电，自动停止运行！" \
          -e "/^RUNNING_NUM=/c RUNNING_NUM=已自动停止检测！" "${MODDIR}/files/status.conf"
      fi
    fi
  elif [ ! -f ${MODDIR}/disable ]; then
    if [ "$(frpc_pid_check)" -ne 0 ]; then
      check_reload
    elif [ "$(frpc_pid_check)" -eq 0 ]; then
      runing_start
    elif [ "$(process)" -eq 0 ]; then
      runing_start
    fi
  else
    if [ "$(frpc_pid_check)" -ne 0 ]; then
      {
        kill -9 "$(frpc_pid_check)"
        rm -f "${MODDIR}/files/frpc_run.pid"
      }
      if [ "$?" -eq 0 ]; then
        sed -i -e "/^CHECK_FILE_STATUS=/c CHECK_FILE_STATUS=已手动停止检测！" \
          -e "/^RUNNING_STATUS=/c RUNNING_STATUS=已手动停止运行（重新打开则自动重启FRPC，无需设备重启）" \
          -e "/^RUNNING_NUM=/c RUNNING_NUM=已手动停止检测！" "${MODDIR}/files/status.conf"
      fi
    elif [ "$(process)" -ne 0 ]; then
      { kill -9 "$(ps -ef | grep "frpc-${F_ARCH}" | grep -v grep | awk '{ print $2 }')"; }
      if [ "$?" -eq 0 ]; then
        sed -i -e "/^CHECK_FILE_STATUS=/c CHECK_FILE_STATUS=已手动停止检测！" \
          -e "/^RUNNING_STATUS=/c RUNNING_STATUS=已手动停止运行（重新打开则自动重启FRPC，无需设备重启）" \
          -e "/^RUNNING_NUM=/c RUNNING_NUM=已手动停止检测！" "${MODDIR}/files/status.conf"
      fi
    fi
  fi
  FRPC_CPU_Usage=$(frpc_cpu_usage_check)
  FRPC_VmRSS=$(frpc_vmrss_check)
  sleep 1
  . ${MODDIR}/files/status.conf
  if [ ! -f ${MODDIR}/update ]; then
    sed -i "/^description=/c description=使用Magisk挂载运行通用FRPC程序。[状态：${RUNNING_STATUS}；CPU占用（avg）：${FRPC_CPU_Usage:-NuLL}；物理内存占用：${FRPC_VmRSS:-NuLL}]，[配置文件状态：${CHECK_FILE_STATUS}；穿透服务数：${RUNNING_NUM}，自动重载配置文件 ${RELOAD_NUM} 次]" "${MODDIR}/module.prop"
  else
    sed -i "/^description=/c description=使用Magisk挂载运行通用FRPC程序。[状态：${RUNNING_STATUS}，CPU占用（avg）：${FRPC_CPU_Usage:-Null}；物理内存占用：${FRPC_VmRSS:-NuLL}]，[配置文件状态：${CHECK_FILE_STATUS}；穿透服务数：${RUNNING_NUM}，自动重载配置文件 ${RELOAD_NUM} 次]（模块新设定将在设备重启后生效！）" "${MODDIR}/module.prop"
  fi
}

if [ -f "${MODDIR}/screen" ]; then
  main
elif [ "$(screen_status)" -eq 0 ]; then
  main
fi
