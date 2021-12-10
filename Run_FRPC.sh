#!/system/bin/sh
MODDIR=${0%/*}
DATADIR="/sdcard/Android"
. ${MODDIR}/files/status.conf

start_frpc(){
	nohup ${MODDIR}/files/bin/frpc-${F_ARCH} -c ${DATADIR}/frpc/frpc.ini &>/dev/null &
}

verify_frpc(){
	${MODDIR}/files/bin/frpc-${F_ARCH} verify -c ${DATADIR}/frpc/frpc.ini
}

reload_frpc(){
	${MODDIR}/files/bin/frpc-${F_ARCH} reload -c ${DATADIR}/frpc/frpc.ini
}


if [[ $# -ne 0 ]]; then
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
	esac
else
	exit 1
fi