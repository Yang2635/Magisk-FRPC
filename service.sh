#!/system/bin/sh
MODDIR=${0%/*}
. ${MODDIR}/files/status.conf

DATADIR="/sdcard/Android"
Busybox_file="${MODDIR}/files/bin/busybox_${F_ARCH}"

until [[ $(getprop sys.boot_completed) -eq 1 ]]; do
	sleep 1
done

sed -i -e "/^RELOAD_NUM=/c RELOAD_NUM=NULL" -e "/^RUNNING_STATUS=/c RUNNING_STATUS=FRPC未运行！" -e "/^CHECK_FILE_STATUS=/c CHECK_FILE_STATUS=未进行配置文件检测！" "${MODDIR}/files/status.conf"

PROCESS()
{
	ps -ef | grep "Check_FRPC.sh" | grep -v grep | wc -l
}

Set_Crond(){
	[[ ! -d "${MODDIR}/crond" ]] && mkdir ${MODDIR}/crond
	if [[ ! -f "${MODDIR}/crond/root" ]]; then
		touch ${MODDIR}/crond/root
		chmod 0700 ${MODDIR}/crond/root
	elif [[ ! -x "${MODDIR}/crond/root" ]]; then
		chmod 0700 ${MODDIR}/crond/root
	fi
	[[ -s "${MODDIR}/crond/root" ]] || echo "*/1 * * * * sh ${MODDIR}/Check_FRPC.sh &>/dev/null" > ${MODDIR}/crond/root
}

[[ ! -d ${DATADIR}/frpc/logs ]] && mkdir -p ${DATADIR}/frpc/logs
[[ ! -f ${DATADIR}/frpc/frpc.ini ]] && cp -af ${MODDIR}/files/frpc.ini ${DATADIR}/frpc/frpc.ini
chmod -R 0644 ${MODDIR}/files/status.conf

if [[ -f "${Busybox_file}" ]] && [[ -x "${Busybox_file}" ]]; then
	Set_Crond
	${Busybox_file} crond -c ${MODDIR}/crond
elif [[ "$(which crond)" ]]; then
	Set_Crond
	crond -c ${MODDIR}/crond
else
	until [[ $(PROCESS) -ne 0 ]]; do
		nohup sh ${MODDIR}/Check_FRPC.sh &>/dev/null 2>&1 &
		sleep 5
	done
fi
