#!/system/bin/sh
#MODDIR=${0%/*}
MODDIR="$(dirname $(readlink -f "$0"))"
. ${MODDIR}/files/status.conf
F_ARCH="${F_ARCH:=arm64}"
DATADIR="${DATADIR:=/sdcard/Android}"
export PATH=${MODDIR}/files/bin/busybox:$PATH

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

set_crond
crond -c ${MODDIR}/crond
sh ${MODDIR}/check_frpc.sh &>/dev/null
