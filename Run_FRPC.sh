#!/system/bin/sh
MODDIR=${0%/*}
DATADIR="/sdcard/Android"
. ${MODDIR}/files/status.conf

Start_FRPC(){
	nohup ${MODDIR}/files/bin/frpc-${F_ARCH} -c ${DATADIR}/frpc/frpc.ini &>/dev/null &
}

Verify_FRPC(){
	${MODDIR}/files/bin/frpc-${F_ARCH} verify -c ${DATADIR}/frpc/frpc.ini
}

Reload_FRPC(){
	${MODDIR}/files/bin/frpc-${F_ARCH} reload -c ${DATADIR}/frpc/frpc.ini
}


if [[ $# -ne 0 ]]; then
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
	esac
else
	exit 1
fi