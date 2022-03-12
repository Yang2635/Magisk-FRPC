SKIPUNZIP=1

DATADIR='/sdcard/Android'
VERSION='v2.9'
VERSIONCODE='20220312'

unzip -o "${ZIPFILE}" 'module.prop' -d "${TMPDIR}" >&2
[[ ! -f "${TMPDIR}/module.prop" ]] && abort "! 未找到module.prop文件，安装结束！"

Cus_Print(){
	ui_print "$@"
	sleep 0.03
}

file="META-INF/com/google/android/update-binary"
file_path="${TMPDIR}/${file}"
hash_path="${file_path}.sha256sum"
unzip -o "${ZIPFILE}" "META-INF/com/google/android/*" -d "${TMPDIR}" >&2
[ -f "${file_path}" ] || abort "! ${file} 不存在！"
if [ -f "${hash_path}" ]; then
  (echo "$(cat "${hash_path}")  ${file_path}" | sha256sum -c -s -) || abort "！校验：${file} 错误！"
  Cus_Print "- 校验：${file}" >&1
else
  abort "！缺少校验文件！"
fi

# extract <zip> <file> <target dir> <junk paths>
extract(){
  zip=$1
  file=$2
  dir=$3
  junk_paths=$4
  [ -z "${junk_paths}" ] && junk_paths=false
  opts="-o"
  [ ${junk_paths} = true ] && opts="-oj"

  file_path=""
  hash_path=""
  if [ ${junk_paths} = true ]; then
    file_path="${dir}/$(basename "${file}")"
    hash_path="${TMPDIR}/$(basename "${file}").sha256sum"
  else
    file_path="${dir}/${file}"
    hash_path="${TMPDIR}/${file}.sha256sum"
  fi

  unzip ${opts} "${zip}" "${file}" -d "${dir}" >&2
  [ -f "${file_path}" ] || abort "! ${file} 不存在！"

  unzip ${opts} "${zip}" "${file}.sha256sum" -d "${TMPDIR}" >&2
  [ -f "${hash_path}" ] || abort "! ${file}.sha256sum 不存在！"

  (echo "$(cat "${hash_path}")  ${file_path}" | sha256sum -c -s -) || abort "! 校验：${file} 错误！"
  Cus_Print "- 校验：${file}" >&1
}

author="`grep_prop author ${TMPDIR}/module.prop`"
name="`grep_prop name ${TMPDIR}/module.prop`"

mkdir -p "${MODPATH}/files/bin"

Get_Choose(){
	local choose
	local branch
	while :; do
		choose="$(getevent -qlc 1 | awk '{ print $3 }')"
		case "$choose" in
			KEY_VOLUMEUP)
				branch="0"
			;;
			KEY_VOLUMEDOWN)
				branch="1"
			;;
			*)
				continue
			;;
		esac
		echo "${branch}"
		break
	done
}

#Check whether the directory is readable and writable
Sdcard_RW(){
	local test_file="${DATADIR}/.A_TEST_FILE"
	touch $test_file
	rm $test_file
}

#Check architecture
Check_ARCH(){
	case ${ARCH} in
	arm64)
		F_ARCH=${ARCH}
	;;
	arm)
		F_ARCH=${ARCH}
	;;
	x64)
		F_ARCH=x86_64
	;;
	x86)
		F_ARCH=${ARCH}
	;;
	*)
		Cus_Print "- 不支持的架构: ${ARCH}"
		Cus_Print " "
		abort "! 安装结束！"
	;;
	esac
}

Check_Crond(){
	Busybox_file="${MODPATH}/files/bin/busybox_${F_ARCH}"
	if [[ -x "${Busybox_file}" ]]; then
		Cus_Print "- 已优先使用模块的定时任务方式检测运行状态！"
		sed -i "/^RUNNING_METHOD=/c RUNNING_METHOD=定时任务（模块提供）" "${MODPATH}/files/status.conf"
	elif [[ "$(which crond)" ]]; then
		Cus_Print "- 设备重启后将以定时任务方式检测运行状态！"
		sed -i "/^RUNNING_METHOD=/c RUNNING_METHOD=定时任务" "${MODPATH}/files/status.conf"
	else
		Cus_Print "- 设备重启后将以默认方式检测运行状态！"
		sed -i "/^RUNNING_METHOD=/c RUNNING_METHOD=默认" "${MODPATH}/files/status.conf"
	fi
}

Cus_Print " "
Cus_Print "(#) 设备信息： "
Cus_Print "- 品牌: `getprop ro.product.brand`"
Cus_Print "- 代号: `getprop ro.product.device`"
Cus_Print "- 模型: `getprop ro.product.model`"
Cus_Print "- 安卓版本: `getprop ro.build.version.release`"
[[ "`getprop ro.miui.ui.version.name`" != "" ]] && Cus_Print "- MIUI版本: MIUI `getprop ro.miui.ui.version.name` - `getprop ro.build.version.incremental`"
Cus_Print "- 内核版本: `uname -osr`"
Cus_Print "- 运存大小: `free -m | grep -E "^Mem|^内存" | awk '{printf("总量：%s MB，已用：%s MB，剩余：%s MB，使用率：%.2f%%",$2,$3,($2-$3),($3/$2*100))}'`"
Cus_Print "- Swap大小: `free -m | grep -E "^Swap|^交换" | awk '{printf("总量：%s MB，已用：%s MB，剩余：%s MB，使用率：%.2f%%",$2,$3,$4,($3/$2*100))}'`"
Cus_Print " "
Cus_Print "(@) 模块信息："
Cus_Print "- 名称: ${name}"
Cus_Print "- 作者：${author}"
Cus_Print " "
Sdcard_RW
[[ $? -ne 0 ]] && abort "! ${DATADIR} 目录读写测试失败，安装结束！"
Check_ARCH
Cus_Print "- 设备架构：${F_ARCH}"
Cus_Print " "
Cus_Print "(?) 确认安装吗？(请选择)"
Cus_Print "- 按音量键＋: 安装 √"
Cus_Print "- 按音量键－: 退出 ×"
if [[ $(Get_Choose) -eq 0 ]]; then
	Cus_Print "- 已选择安装！"
	Cus_Print " "
	Cus_Print "- 正在校验、释放所需文件！"
	extract "${ZIPFILE}" "files/bin/frpc-${F_ARCH}" "${MODPATH}/files/bin" true
	extract "${ZIPFILE}" "files/bin/busybox_${F_ARCH}" "${MODPATH}/files/bin" true
	extract "${ZIPFILE}" "service.sh" "${MODPATH}"
	extract "${ZIPFILE}" "module.prop" "${MODPATH}"
	extract "${ZIPFILE}" "uninstall.sh" "${MODPATH}"
	extract "${ZIPFILE}" "Run_FRPC.sh" "${MODPATH}"
	extract "${ZIPFILE}" "Check_FRPC.sh" "${MODPATH}"
	extract "${ZIPFILE}" "update_log.md" "${MODPATH}"
	extract "${ZIPFILE}" "files/status.conf" "${MODPATH}/files" true
	extract "${ZIPFILE}" "files/frpc.ini" "${MODPATH}/files" true
	extract "${ZIPFILE}" "files/frpc_full.ini" "${MODPATH}/files" true
	Cus_Print "- 文件释放完成！正在设置权限！"
	set_perm_recursive ${MODPATH} 0 0 0755 0644
	set_perm_recursive  ${MODPATH}/files/bin 0 0 0755 0755
	Cus_Print "- 权限设置完成！"
	Cus_Print " "
	Check_Crond
	sed -i -e "/^F_ARCH=/c F_ARCH=${F_ARCH}" -e "/^DATADIR=/c DATADIR=\'${DATADIR}\'" "${MODPATH}/files/status.conf"
	FRP_VERSION=$(${MODPATH}/files/bin/frpc-${F_ARCH} -v)
	sed -i -e "/^version=/c version=${VERSION}-\(frpc\: v${FRP_VERSION}\)" -e "/^versionCode=/c versionCode=${VERSIONCODE}" "${MODPATH}/module.prop"
	Cus_Print " "
	Cus_Print "(?) 是否息屏检测配置文件状态？(请选择)"
	Cus_Print "- 按音量键＋: 检  测 √"
	Cus_Print "- 按音量键－: 不检测 ×"
	if [[ $(Get_Choose) -eq 0 ]]; then
		sed -i -e "/^SCREEN_STATUS=/c SCREEN_STATUS=yes" "${MODPATH}/files/status.conf"
		Cus_Print "- 设备息屏将检测配置文件状态！"
		Cus_Print " "
	else
		sed -i -e "/^SCREEN_STATUS=/c SCREEN_STATUS=no" "${MODPATH}/files/status.conf"
		Cus_Print "- 设备息屏将不检测配置文件状态！"
		Cus_Print " "
	fi
	if [[ -f ${DATADIR}/frpc/frpc.ini ]]; then
		cp -af ${MODPATH}/update_log.md ${DATADIR}/frpc/
		Cus_Print "(?) 存在旧配置文件，是否保留原配置文件？(请选择)"
		Cus_Print "- 按音量键＋: 保留"
		Cus_Print "- 按音量键－: 替换"
		if [[ $(Get_Choose) -eq 1 ]]; then
			Cus_Print "- 已选择替换备份原配置文件！"
			now_date=$(date "+%Y%m%d%H%M%S")
			mv ${DATADIR}/frpc/frpc.ini ${DATADIR}/frpc/backup_${now_date}-frpc.ini
			Cus_Print "- 已备份保存为 Android/frpc/backup_${now_date}-frpc.ini"
			cp -af ${MODPATH}/files/frpc.ini ${DATADIR}/frpc/
			Cus_Print "- 已创建新文件！"
			Cus_Print " "
		else
			Cus_Print "- 已选择保留原配置文件！"
			Cus_Print " "
		fi
	else
		if [[ ! -d ${DATADIR}/frpc ]]; then
			mkdir -p ${DATADIR}/frpc
			Cus_Print "- 创建配置文件目录frpc完成！"
			Cus_Print " "
		elif [[ ! -d ${DATADIR}/frpc/logs ]]; then
			mkdir ${DATADIR}/frpc/logs
			Cus_Print "- 创建日志目录frpc/logs完成！"
			Cus_Print " "
		fi
		cp -af ${MODPATH}/files/frpc*.ini ${MODPATH}/update_log.md ${DATADIR}/frpc/
		Cus_Print "- 已创建配置文件！"
		Cus_Print "- 请前往 ${DATADIR}/frpc目录查看frpc.ini文件内使用说明并配置文件！"
		Cus_Print "- 然后进行设备重启即可！"
	fi
else
	abort "! 已选择退出"
fi
