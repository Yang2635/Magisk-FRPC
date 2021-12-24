#!/system/bin/sh

MODDIR=${0%/*}

PROCESS(){
	ps -ef | grep "frpc-${F_ARCH}" | grep -v grep | wc -l
}

Battery_Charge(){
	dumpsys battery | grep powered | grep 'true' | wc -l
}

Battery_Electricity(){
	dumpsys battery | awk '/level: /{print $2}'
}

Screen_status(){
	dumpsys deviceidle | awk -F'=' '/mScreenOn/{print $2}' | sed -e 's/false/1/' -e 's/true/0/'
}

Runing_Start(){
	if [[ -f ${DATADIR}/frpc/frpc.ini ]]; then
		sed -i "/^FILE_STATUS=/c FILE_STATUS=$(stat -c %Y ${DATADIR}/frpc/frpc.ini)" "${MODDIR}/files/status.conf"
		sh ${MODDIR}/Run_FRPC.sh verify
		if [[ $? -eq 0 ]]; then
			sed -i "/^CHECK_FILE_STATUS=/c CHECK_FILE_STATUS=配置文件检测正确！" "${MODDIR}/files/status.conf"
			sh ${MODDIR}/Run_FRPC.sh start
			sleep 5
			if [[ $(PROCESS) -ne 0 ]]; then
				Running_NUM=$(sh ${MODDIR}/Run_FRPC.sh status)
				sed -i -e "/^RUNNING_STATUS=/c RUNNING_STATUS=FRPC正在运行中！" \
				-e "/^RELOAD_NUM=/c RELOAD_NUM=0" -e "/^RUNNING_NUM=/c RUNNING_NUM=${Running_NUM}" \
				"${MODDIR}/files/status.conf"
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

Check_Reload(){
	if [[ -f ${DATADIR}/frpc/frpc.ini ]]; then
		check_new_file_status=$(stat -c %Y ${DATADIR}/frpc/frpc.ini)
		if [[ "${FILE_STATUS}" != "$check_new_file_status" ]]; then
			sh ${MODDIR}/Run_FRPC.sh verify 
			if [[ $? -eq 0 ]]; then
				sh ${MODDIR}/Run_FRPC.sh reload
				if [[ $? -eq 0 ]]; then
					sleep 2
					Running_NUM=$(sh ${MODDIR}/Run_FRPC.sh status)
					sed -i -e "/^RELOAD_NUM=/c RELOAD_NUM=$(($RELOAD_NUM+1))" \ 
					-e "/^FILE_STATUS=/c FILE_STATUS=${check_new_file_status}" \
					-e "/^CHECK_FILE_STATUS=/c CHECK_FILE_STATUS=配置文件检测正确！" \
					-e "/^RUNNING_NUM=/c RUNNING_NUM=${Running_NUM}" "${MODDIR}/files/status.conf"
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

Main(){
	if [[ $(Battery_Electricity) -lt 20 ]] && [[ $(Battery_Charge) -eq 0 ]]; then
		if [[ $(PROCESS) -ne 0 ]]; then
			kill -9 $(ps -ef | grep "frpc-${F_ARCH}" | grep -v grep | awk '{ print $2 }')
			if [[ $? -eq 0 ]]; then
				sed -i -e "/^CHECK_FILE_STATUS=/c CHECK_FILE_STATUS=已自动停止检测！" \
				-e "/^RUNNING_STATUS=/c RUNNING_STATUS=当前电量低于20%且未在充电，自动停止运行！" \
				-e "/^RUNNING_NUM=/c RUNNING_NUM=已自动停止检测！" "${MODDIR}/files/status.conf"
			fi
		else
			sed -i -e "/^CHECK_FILE_STATUS=/c CHECK_FILE_STATUS=已自动停止检测！" \
			-e "/^RUNNING_STATUS=/c RUNNING_STATUS=当前电量低于20%且未在充电，自动停止运行！" \
			-e "/^RUNNING_NUM=/c RUNNING_NUM=已自动停止检测！" "${MODDIR}/files/status.conf"
		fi
	elif [[ ! -f ${MODDIR}/disable ]]; then
		if [[ $(PROCESS) -eq 0 ]]; then
			Runing_Start
		else
			Check_Reload
		fi
	else
		if [[ $(PROCESS) -ne 0 ]]; then
			kill -9 $(ps -ef | grep "frpc-${F_ARCH}" | grep -v grep | awk '{ print $2 }')
			if [[ $? -eq 0 ]]; then
				sed -i -e "/^CHECK_FILE_STATUS=/c CHECK_FILE_STATUS=已手动停止检测！" \
				-e "/^RUNNING_STATUS=/c RUNNING_STATUS=已手动停止运行（重新打开则自动重启FRPC，无需设备重启）" \
				-e "/^RUNNING_NUM=/c RUNNING_NUM=已手动停止检测！" "${MODDIR}/files/status.conf"
			fi
		fi
	fi
	. ${MODDIR}/files/status.conf
	if [[ ! -f ${MODDIR}/update ]]; then
		sed -i "/^description=/c description=使用Magisk挂载运行通用FRPC程序。[状态：$RUNNING_STATUS ]，[配置文件状态：$CHECK_FILE_STATUS；穿透服务数：$RUNNING_NUM，自动重载配置文件 $RELOAD_NUM 次]，[检测方式：$RUNNING_METHOD]" "${MODDIR}/module.prop"
	else
		sed -i "/^description=/c description=使用Magisk挂载运行通用FRPC程序。[状态：$RUNNING_STATUS ]，[配置文件状态：$CHECK_FILE_STATUS；穿透服务数：$RUNNING_NUM，自动重载配置文件 $RELOAD_NUM 次]，[检测方式：$RUNNING_METHOD]（模块新设定将在设备重启后生效！）" "${MODDIR}/module.prop"
	fi
}

Start(){
	. ${MODDIR}/files/status.conf
	Busybox_file="${MODDIR}/files/bin/busybox_${F_ARCH}"
	if [[ ${SCREEN_STATUS} == 'yes' ]]; then
		Main
	elif [[ $(Screen_status) -eq 0 ]]; then
		Main
	fi
}

if [[ ! -f "${Busybox_file}" ]] && [[ -z "$(which crond)" ]]; then
	while :
	do
		Start
		sleep 60
	done
else
	Start
fi