#!/system/bin/sh
MODDIR=${0%/*}
. ${MODDIR}/files/status.conf
MAGISK_BUSYBOX_PATH='/data/adb/magisk/busybox'
cus_busybox_file="${MODDIR}/files/bin/busybox_${F_ARCH}"

until [ "$(getprop sys.boot_completed)" -eq 1 ]; do
  sleep 1
done

sed -i -e "/^RELOAD_NUM=/c RELOAD_NUM=NULL" \
  -e "/^RUNNING_STATUS=/c RUNNING_STATUS=FRPC未运行！" \
  -e "/^CHECK_FILE_STATUS=/c CHECK_FILE_STATUS=未进行配置文件检测！" \
  -e "/^RUNNING_NUM=/c RUNNING_NUM=NULL" "${MODDIR}/files/status.conf"

set_crond() {
  [ ! -d "${MODDIR}/crond" ] && mkdir ${MODDIR}/crond
  if [ ! -f "${MODDIR}/crond/root" ]; then
    touch ${MODDIR}/crond/root
    chmod 0700 ${MODDIR}/crond/root
  elif [ ! -x "${MODDIR}/crond/root" ]; then
    chmod 0700 ${MODDIR}/crond/root
  fi
  [ -s "${MODDIR}/crond/root" ] || echo "*/1 7-23 * * * sh ${MODDIR}/Check_FRPC.sh &>/dev/null" >${MODDIR}/crond/root
}

until [ -d ${DATADIR}/frpc/logs ]; do
  mkdir -p ${DATADIR}/frpc/logs
  sleep 2
done

if [ ! -f "${MODDIR}/files/module.prop.bak" ]; then
  cp "${MODDIR}/module.prop" "${MODDIR}/files/module.prop.bak"
fi

if [ -f ${MODDIR}/files/frpc_run.pid ]; then
  rm -f "${MODDIR}/files/frpc_run.pid"
fi
[ "$(stat -c %a ${MODDIR}/files/status.conf)" != "644" ] && chmod 0644 ${MODDIR}/files/status.conf

if [ -x "${MAGISK_BUSYBOX_PATH}" ]; then
  set_crond
  ${MAGISK_BUSYBOX_PATH} crond -c ${MODDIR}/crond
  sh ${MODDIR}/Check_FRPC.sh &>/dev/null
elif [ "$(which crond)" ]; then
  set_crond
  crond -c ${MODDIR}/crond
  sh ${MODDIR}/Check_FRPC.sh &>/dev/null
elif [ -x "${cus_busybox_file}" ]; then
  set_crond
  ${cus_busybox_file} crond -c ${MODDIR}/crond
  sh ${MODDIR}/Check_FRPC.sh &>/dev/null
else
  sed -i "/^description=/c description=使用Magisk挂载运行通用FRPC程序。[状态：未检测到busybox或系统环境中无crond命令！]" "${MODDIR}/module.prop"
  exit 1
fi
