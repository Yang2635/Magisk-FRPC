SKIPUNZIP=1

DATADIR='/sdcard/Android'
VERSION='v3.0.2'
VERSIONCODE='20221106'
MAGISK_BUSYBOX_PATH='/data/adb/magisk/busybox'

unzip -o "${ZIPFILE}" 'module.prop' -d "${TMPDIR}" >&2
[ ! -f "${TMPDIR}/module.prop" ] && abort "! 未找到 module.prop 文件，安装结束!"

customize_print() {
  ui_print "$@"
  sleep 0.03
}

is_magisk_app(){
    if $BOOTMODE; then
      customize_print "- 从 Magisk 应用程序安装!"
    else
      customize_print "*********************************************************"
      customize_print "! 不支持从 Recovery 中安装!"
      customize_print "! 请安装 Magisk 应用程序并在 Magisk 应用程序中安装!"
      abort "*********************************************************"
    fi
}

file="META-INF/com/google/android/update-binary"
file_path="${TMPDIR}/${file}"
hash_path="${file_path}.sha256sum"
unzip -o "${ZIPFILE}" "META-INF/com/google/android/*" -d "${TMPDIR}" >&2
[ -f "${file_path}" ] || abort "! ${file} 不存在!"
if [ -f "${hash_path}" ]; then
  (echo "$(cat "${hash_path}")  ${file_path}" | sha256sum -c -s -) || abort "! 校验：${file} 错误!"
  customize_print "- 校验：${file}" >&1
else
  customize_print "- 从 Magisk 在线更新安裝!"
fi

# extract <zip> <file> <target dir> <junk paths>
extract() {
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
  [ -f "${file_path}" ] || abort "! ${file} 不存在!"

  unzip ${opts} "${zip}" "${file}.sha256sum" -d "${TMPDIR}" >&2
  [ -f "${hash_path}" ] || abort "! ${file}.sha256sum 不存在!"

  (echo "$(cat "${hash_path}")  ${file_path}" | sha256sum -c -s -) || abort "! 校验：${file} 错误!"
  customize_print "- 校验：${file}" >&1
}

author="$(grep_prop author ${TMPDIR}/module.prop)"
name="$(grep_prop name ${TMPDIR}/module.prop)"

is_magisk_app

mkdir -p "${MODPATH}/files/bin"

# Detect volume key selection
get_choose() {
  local choose branch
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

# Check whether the directory is readable and writable
sdcard_RW() {
  local test_file="${DATADIR}/.FRPC_MODULE_TEST_FILE"
  { touch $test_file; rm $test_file;}
  echo $?
}

# Check architecture
check_arch() {
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
    customize_print "- 不支持的架构: ${ARCH}"
    customize_print " "
    abort "! 安装结束!"
    ;;
  esac
}

# Detect whether the system environment contains the Busybox tool
check_busybox() {
  local cus_busybox_file="${MODPATH}/files/bin/busybox_${F_ARCH}"
  if [ -x "${MAGISK_BUSYBOX_PATH}" ]; then
    customize_print "- 检测到 Magisk 的 Busybox 工具!"
  elif [ "$(which crond)" ]; then
    customize_print "- 检测到系统环境中存在 crond 命令!"
  elif [ -x "${cus_busybox_file}" ]; then
    customize_print "- 检测到模块提供的 Busybox 工具!"
  else
    abort "! 未检测到相关 Busybox 工具或所需命令!"
  fi
}

customize_print " "
customize_print "(#) 设备信息： "
customize_print "- 品牌: $(getprop ro.product.brand)"
customize_print "- 代号: $(getprop ro.product.device)"
customize_print "- 模型: $(getprop ro.product.model)"
customize_print "- 安卓版本: $(getprop ro.build.version.release)"
[ "$(getprop ro.miui.ui.version.name)" != "" ] && customize_print "- MIUI版本: MIUI $(getprop ro.miui.ui.version.name) - $(getprop ro.build.version.incremental)"
customize_print "- 内核版本: $(uname -osr)"
customize_print "- 运存大小: $(free -m | grep -E "^Mem|^内存" | awk '{printf("总量：%s MB，已用：%s MB，剩余：%s MB，使用率：%.2f%%",$2,$3,($2-$3),($3/$2*100))}')"
customize_print "- Swap大小: $(free -m | grep -E "^Swap|^交换" | awk '{printf("总量：%s MB，已用：%s MB，剩余：%s MB，使用率：%.2f%%",$2,$3,$4,($3/$2*100))}')"
customize_print " "
customize_print "(@) 模块信息："
customize_print "- 名称: ${name}"
customize_print "- 作者：${author}"
customize_print " "
[ "$(sdcard_RW)" -ne 0 ] && abort "! 目录读写测试失败，安装结束!"
check_arch
customize_print "- 设备架构：${F_ARCH}"
customize_print " "
customize_print "(?) 确认安装吗？(请选择)"
customize_print "- 按音量键＋: 安装 √"
customize_print "- 按音量键－: 退出 ×"
if [ "$(get_choose)" -eq 0 ]; then
  customize_print "- 已选择安装!"
  customize_print " "
  customize_print "- 正在校验、释放所需文件!"
  extract "${ZIPFILE}" "files/bin/frpc-${F_ARCH}" "${MODPATH}/files/bin" true
  extract "${ZIPFILE}" "files/bin/busybox_${F_ARCH}" "${MODPATH}/files/bin" true
  extract "${ZIPFILE}" "service.sh" "${MODPATH}"
  extract "${ZIPFILE}" "module.prop" "${MODPATH}"
  extract "${ZIPFILE}" "functions.sh" "${MODPATH}"
  extract "${ZIPFILE}" "uninstall.sh" "${MODPATH}"
  extract "${ZIPFILE}" "Run_FRPC.sh" "${MODPATH}"
  extract "${ZIPFILE}" "Check_FRPC.sh" "${MODPATH}"
  extract "${ZIPFILE}" "update_log.md" "${MODPATH}"
  extract "${ZIPFILE}" "files/status.conf" "${MODPATH}/files" true
  extract "${ZIPFILE}" "files/frpc.ini" "${MODPATH}/files" true
  extract "${ZIPFILE}" "files/frpc_full.ini" "${MODPATH}/files" true
  customize_print "- 文件释放完成，正在设置权限!"
  set_perm_recursive ${MODPATH} 0 0 0755 0644
  set_perm_recursive ${MODPATH}/files/bin 0 0 0755 0755
  customize_print "- 权限设置完成!"
  customize_print " "
  check_busybox
  sed -i -e "/^F_ARCH=/c F_ARCH=${F_ARCH}" -e "/^DATADIR=/c DATADIR=\'${DATADIR}\'" "${MODPATH}/files/status.conf"
  FRP_VERSION=$(${MODPATH}/files/bin/frpc-${F_ARCH} -v)
  sed -i -e "/^version=/c version=${VERSION}-\(frpc\: v${FRP_VERSION}\)" -e "/^versionCode=/c versionCode=${VERSIONCODE}" "${MODPATH}/module.prop"
  customize_print " "
  customize_print "(?) 是否息屏检测配置文件状态？(请选择)"
  customize_print "- 按音量键＋: 检  测 √"
  customize_print "- 按音量键－: 不检测 ×"
  if [ "$(get_choose)" -eq 0 ]; then
    touch ${MODPATH}/screen
    customize_print "- 设备息屏将检测配置文件状态!"
    customize_print " "
  else
    customize_print "- 设备息屏将不检测配置文件状态!"
    customize_print " "
  fi
  if [ -f ${DATADIR}/frpc/frpc.ini ]; then
    cp -af ${MODPATH}/update_log.md ${DATADIR}/frpc/
    customize_print "(?) 存在旧配置文件，是否保留原配置文件？(请选择)"
    customize_print "- 按音量键＋: 保留"
    customize_print "- 按音量键－: 替换"
    if [ "$(get_choose)" -eq 1 ]; then
      customize_print "- 已选择替换备份原配置文件!"
      now_date=$(date "+%Y%m%d%H%M%S")
      mv ${DATADIR}/frpc/frpc.ini ${DATADIR}/frpc/backup_${now_date}-frpc.ini
      customize_print "- 已备份保存为 Android/frpc/backup_${now_date}-frpc.ini"
      cp -af ${MODPATH}/files/frpc.ini ${DATADIR}/frpc/
      customize_print "- 已创建新文件!"
      customize_print " "
    else
      customize_print "- 已选择保留原配置文件!"
      customize_print " "
    fi
  else
    if [ ! -d ${DATADIR}/frpc ]; then
      mkdir -p ${DATADIR}/frpc
      customize_print "- 创建配置文件目录 frpc 完成!"
      customize_print " "
    elif [ ! -d ${DATADIR}/frpc/logs ]; then
      mkdir ${DATADIR}/frpc/logs
      customize_print "- 创建日志目录 frpc/logs 完成!"
      customize_print " "
    fi
    cp -af ${MODPATH}/files/frpc*.ini ${MODPATH}/update_log.md ${DATADIR}/frpc/
    customize_print "- 已创建配置文件!"
    customize_print "- 请前往 ${DATADIR}/frpc 目录查看 frpc.ini 文件内使用说明并配置文件!"
    customize_print "- 然后进行设备重启即可!"
  fi
else
  abort "! 已选择退出"
fi
