#!/system/bin/sh
#MODDIR=${0%/*}
MODDIR="$(dirname $(readlink -f "$0"))"
. ${MODDIR}/files/status.conf

start_frpc() {
  nohup ${MODDIR}/files/bin/frpc-${F_ARCH} -c ${DATADIR}/frpc/frpc.ini >/dev/null 2>&1 &
  echo "$!" >${MODDIR}/files/frpc_run.pid
}

verify_frpc() {
  ${MODDIR}/files/bin/frpc-${F_ARCH} verify -c ${DATADIR}/frpc/frpc.ini >/dev/null 2>&1
}

reload_frpc() {
  ${MODDIR}/files/bin/frpc-${F_ARCH} reload -c ${DATADIR}/frpc/frpc.ini
}

work_status() {
  ${MODDIR}/files/bin/frpc-${F_ARCH} status -c ${DATADIR}/frpc/frpc.ini | grep "running" | wc -l
}

if [ $# -ne 0 ]; then
  case "$1" in
  start)
    start_frpc
    ;;
  reload)
    reload_frpc
    ;;
  verify)
    verify_frpc
    ;;
  status)
    work_status
    ;;
  esac
fi
