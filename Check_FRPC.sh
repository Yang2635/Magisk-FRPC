#!/system/bin/sh

MODDIR=${0%/*}
. ${MODDIR}/files/status.conf

DATADIR="/sdcard/Android"
Busybox_file="${MODDIR}/files/bin/busybox_${F_ARCH}"

PROCESS()
{
	ps -ef | grep "frpc-${F_ARCH}" | grep -v grep | wc -l
}

runing_start(){
	if [[ -f ${DATADIR}/frpc/frpc.ini ]]; then
		sed -i "/^FILE_STATUS=/c FILE_STATUS=$(stat ${DATADIR}/frpc/frpc.ini | grep "Modify" | awk '{print $2,$3}' | sed "s/[^0-9]//g")" "${MODDIR}/files/status.conf"
		sh ${MODDIR}/Run_FRPC.sh verify
		if [[ $? -eq 0 ]]; then
			sed -i "/^CHECK_FILE_STATUS=/c CHECK_FILE_STATUS=配置文件检测正确！" "${MODDIR}/files/status.conf"
			sh ${MODDIR}/Run_FRPC.sh start
			sleep 1
			if [[ $(PROCESS) -ne 0 ]]; then
				sed -i -e "/^RUNNING_STATUS=/c RUNNING_STATUS=FRPC正在运行中！" -e "/^RELOAD_NUM=/c RELOAD_NUM=0" "${MODDIR}/files/status.conf"
			else
				sed -i "/^RUNNING_STATUS=/c RUNNING_STATUS=FRPC启动失败！" "${MODDIR}/files/status.conf"
			fi
		else
			sed -i -e "/^CHECK_FILE_STATUS=/c CHECK_FILE_STATUS=配置文件检测错误，请自查配置文件！" -e "/^RUNNING_STATUS=/c RUNNING_STATUS=FRPC未运行！" "${MODDIR}/files/status.conf"
		fi
	else
		sed -i -e "/^CHECK_FILE_STATUS=/c CHECK_FILE_STATUS=Android\/frpc目录下未找到frpc\.ini文件！" -e "/^RUNNING_STATUS=/c RUNNING_STATUS=FRPC未运行！" "${MODDIR}/files/status.conf"
	fi
}

check_reload(){
	if [[ -f ${DATADIR}/frpc/frpc.ini ]]; then
		check_new_file_status=$(stat ${DATADIR}/frpc/frpc.ini | grep "Modify" | awk '{print $2,$3}' | sed "s/[^0-9]//g")
		if [[ "${FILE_STATUS}" != "$check_new_file_status" ]]; then
			sh ${MODDIR}/Run_FRPC.sh verify
			if [[ $? -eq 0 ]]; then
				sh ${MODDIR}/Run_FRPC.sh reload
				if [[ $? -eq 0 ]]; then
					sed -i -e "/^RELOAD_NUM=/c RELOAD_NUM=$(($RELOAD_NUM+1))" -e "/^FILE_STATUS=/c FILE_STATUS=${check_new_file_status}" -e "/^CHECK_FILE_STATUS=/c CHECK_FILE_STATUS=配置文件检测正确！" "${MODDIR}/files/status.conf"
				else
					sed -i "/^CHECK_FILE_STATUS=/c CHECK_FILE_STATUS=配置文件检测正确但重载失败，请自查配置文件！（已保持当前运行状态）" "${MODDIR}/files/status.conf"
				fi
			else
				sed -i "/^CHECK_FILE_STATUS=/c CHECK_FILE_STATUS=配置文件检测错误，请自查配置文件！（已保持当前运行状态）" "${MODDIR}/files/status.conf"
			fi
		fi
	else
		sed -i "/^CHECK_FILE_STATUS=/c CHECK_FILE_STATUS=Android\/frpc目录下未找到frpc\.ini文件！（已保持当前运行状态）" "${MODDIR}/files/status.conf"
	fi
}

main(){
	if [[ ! -f ${MODDIR}/disable ]]; then
		if [[ $(PROCESS) -eq 0 ]]; then
			runing_start
		else
			check_reload
		fi
	else
		if [[ $(PROCESS) -ne 0 ]]; then
			kill -9 $(ps -ef | grep "frpc-${F_ARCH}" | grep -v grep | awk '{ print $2 }')
			if [[ $? -eq 0 ]]; then
				sed -i -e "/^CHECK_FILE_STATUS=/c CHECK_FILE_STATUS=已手动停止检测！" -e "/^RUNNING_STATUS=/c RUNNING_STATUS=已手动停止运行（重新打开则自动重启FRPC，无需设备重启）" "${MODDIR}/files/status.conf"
			fi
		fi
	fi
	. ${MODDIR}/files/status.conf
	if [[ ! -f ${MODDIR}/update ]]; then
		sed -i "/^description=/c description=使用Magisk挂载运行通用FRPC程序。[状态：$RUNNING_STATUS ]，[配置文件状态：$CHECK_FILE_STATUS；自动重载配置文件 $RELOAD_NUM 次]，[设备架构：$F_ARCH，检测方式：$RUNNING_METHOD]" "${MODDIR}/module.prop"
	else
		sed -i "/^description=/c description=使用Magisk挂载运行通用FRPC程序。[状态：$RUNNING_STATUS ]，[配置文件状态：$CHECK_FILE_STATUS；自动重载配置文件 $RELOAD_NUM 次]，[设备架构：$F_ARCH，检测方式：$RUNNING_METHOD]（模块新设定将在设备重启后生效！）" "${MODDIR}/module.prop"
	fi
}

if [[ ! -f "${Busybox_file}" ]] && [[ -z "$(which crond)" ]]; then
	while :
	do
		main
		sleep 60
	done
else
	main
fi