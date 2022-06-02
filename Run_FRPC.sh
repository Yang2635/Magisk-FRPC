#!/system/bin/sh
MODDIR=${0%/*}
. ${MODDIR}/files/status.conf

Start_FRPC() {
  nohup ${MODDIR}/files/bin/frpc-${F_ARCH} -c ${DATADIR}/frpc/frpc.ini >/dev/null 2>&1 &
  echo "$!" >${MODDIR}/files/frpc_run.pid
}

Verify_FRPC() {
  ${MODDIR}/files/bin/frpc-${F_ARCH} verify -c ${DATADIR}/frpc/frpc.ini
}

Reload_FRPC() {
  ${MODDIR}/files/bin/frpc-${F_ARCH} reload -c ${DATADIR}/frpc/frpc.ini
}

Work_Status() {
  ${MODDIR}/files/bin/frpc-${F_ARCH} status -c ${DATADIR}/frpc/frpc.ini | grep "running" | wc -l
}

if [ $# -ne 0 ]; then
  case "$1" in
  start)
    Start_FRPC
    ;;
  reload)
    Reload_FRPC
    ;;
  verify)
    Verify_FRPC
    ;;
  status)
    Work_Status
    ;;
  esac
else
  exit 1
fi
