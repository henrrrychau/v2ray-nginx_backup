#!/bin/bash
Green_font="\033[32m" && Yellow_font="\033[33m" && Red_font="\033[31m" && Font_suffix="\033[0m"
Info="${Green_font}[Info]${Font_suffix}"
Error="${Red_font}[Error]${Font_suffix}"
echo -e "
${Green_font}
#================================================
# 脚本: bbrplus lkl-haproxy
# 版本: 1.0.7
# 作者: mzz2017
# Github: https://github.com/mzz2017/lkl-haproxy
#================================================
${Font_suffix}"
Updated=""

pkg_update(){
	if [ "`cat /etc/issue | grep -iE "debian"`" ] || [ "`cat /etc/issue | grep -iE "ubuntu"`" ]
	then
		apt-get update
	elif [ -f "/etc/redhat-release" ] && [ "`cat /etc/redhat-release | grep -iE "centos"`" ]
	then
		# yum update
		echo "ok"
	elif [ "`cat /etc/issue | grep -iE "alpine"`" ]
	then
		apk update
	else
		echo -e "不支持的 linux 发行版: $(cut -d\\ -f 1 /etc/issue|head -n 1)"
		exit 1
	fi
	Updated="1"
}

pkg_install(){
	if [[ -z $Updated ]]
	then
		pkg_update
	fi

	if [ "`cat /etc/issue | grep -iE "debian"`" ] || [ "`cat /etc/issue | grep -iE "ubuntu"`" ]
	then
		apt-get install -y $@
	elif [ -f "/etc/redhat-release" ] && [ "`cat /etc/redhat-release | grep -iE "centos"`" ]
	then
		yum install -y $@
	elif [ "`cat /etc/issue | grep -iE "alpine"`" ]
	then
		apk add $@
	else
		echo -e "不支持的 linux 发行版: $(cut -d\\ -f 1 /etc/issue|head -n 1)"
		exit 1
	fi
}

pkg_uninstall(){
	if [ "`cat /etc/issue | grep -iE "debian"`" ] || [ "`cat /etc/issue | grep -iE "ubuntu"`" ]
	then
		apt-get remove -y $@
	elif [ -f "/etc/redhat-release" ] && [ "`cat /etc/redhat-release | grep -iE "centos"`" ]
	then
		yum remove -y $@
	elif [ "`cat /etc/issue | grep -iE "alpine"`" ]
	then
		apk del $@
	else
		echo -e "不支持的 linux 发行版: $(cut -d\\ -f 1 /etc/issue|head -n 1)"
		exit 1
	fi
}


start(){
	if [ "`cat /etc/issue | grep -iE "debian"`" ] || [ "`cat /etc/issue | grep -iE "ubuntu"`" ] || ([ -f "/etc/redhat-release" ] && [ "`cat /etc/redhat-release | grep -iE "centos"`" ])
	then
		systemctl restart lkl-haproxy
	elif [ "`cat /etc/issue | grep -iE "alpine"`" ]
	then
		rc-service lkl-haproxy restart
	else
		echo -e "不支持的 linux 发行版: $(cut -d\\ -f 1 /etc/issue|head -n 1)"
		exit 1
	fi
}

enable(){
	if [ "`cat /etc/issue | grep -iE "debian"`" ] || [ "`cat /etc/issue | grep -iE "ubuntu"`" ] || ([ -f "/etc/redhat-release" ] && [ "`cat /etc/redhat-release | grep -iE "centos"`" ])
	then
		wget --no-cache -O /etc/systemd/system/lkl-haproxy.service https://github.com/mzz2017/lkl-haproxy/raw/master/requirement/lkl-haproxy.service
		systemctl daemon-reload
		systemctl enable lkl-haproxy
	elif [ "`cat /etc/issue | grep -iE "alpine"`" ]
	then
		command -v openrc || apk add openrc
		wget --no-cache -O /etc/init.d/lkl-haproxy https://github.com/mzz2017/lkl-haproxy/raw/master/requirement/alpine/lkl-haproxy
		chmod 0755 /etc/init.d/lkl-haproxy
		rc-update add lkl-haproxy boot
	else
		echo -e "不支持的 linux 发行版: $(cut -d\\ -f 1 /etc/issue|head -n 1)"
		exit 1
	fi
}

disable(){
	if [ "`cat /etc/issue | grep -iE "debian"`" ] || [ "`cat /etc/issue | grep -iE "ubuntu"`" ] || ([ -f "/etc/redhat-release" ] && [ "`cat /etc/redhat-release | grep -iE "centos"`" ])
	then
		systemctl disable lkl-haproxy
	elif [ "`cat /etc/issue | grep -iE "alpine"`" ]
	then
		rc-update del lkl-haproxy boot
	else
		echo -e "不支持的 linux 发行版: $(cut -d\\ -f 1 /etc/issue|head -n 1)"
		exit 1
	fi
}

check_system(){
	[[ "`uname -m`" != "x86_64" ]] && echo -e "${Error} 只支持 x86_64 !" && exit 1
}

check_root(){
	[[ "`id -u`" != "0" ]] && echo -e "${Error} 请使用具有 root 权限的用户 !" && exit 1
}

# glibc
check_ldd(){
	#ldd=`ldd --version | grep ldd | awk '{print $NF}'`
	if [ "`cat /etc/issue | grep -iE "debian"`" ] || [ "`cat /etc/issue | grep -iE "ubuntu"`" ] || ([ -f "/etc/redhat-release" ] && [ "`cat /etc/redhat-release | grep -iE "centos"`" ])
	then
		if [[ "`ldd --version | grep ldd | awk '{print $NF}'`" < "2.14" ]]
		then
			echo -e "${Error} glibc 版本低于 2.14, 不支持 !" && exit 1
		fi
	elif [ "`cat /etc/issue | grep -iE "alpine"`" ]
	then
		if [[ ! -f "/usr/glibc-compat/lib/libc.so.6" ]] || [[ "`/usr/glibc-compat/lib/libc.so.6 | grep libc | awk '{print $NF}'`" < "2.14" ]]
		then
			# https://github.com/sgerrand/alpine-pkg-glibc
			wget -O glibc.apk https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.22-r8/glibc-2.22-r8.apk
			apk add --allow-untrusted glibc.apk
		fi
		# requirements
		wget --no-cache -O sorequirements.txt https://github.com/mzz2017/lkl-haproxy/raw/master/requirement/alpine/sorequirements.txt
		cat sorequirements.txt | while read -r line;do wget --no-clobber -O /usr/glibc-compat/lib/$line https://github.com/mzz2017/lkl-haproxy/raw/master/requirement/alpine/$line;done
	else
		echo -e "不支持的 linux 发行版: $(cut -d\\ -f 1 /etc/issue|head -n 1)"
		exit 1
	fi
}

check_tuntap(){
	echo -e "\n"

	if [ "`cat /etc/issue | grep -iE "alpine"`" ]
	then
		if [ ! -f "/etc/modules-load.d/tun.conf" ]
		then
			modprobe tun
			echo "tun" >> /etc/modules-load.d/tun.conf
		fi
	fi

	cat /dev/net/tun

	echo -e "${Info} 请确认上一行的返回值是否为 'File descriptor in bad state'（文件描述符处于错误状态） ？"
	echo -e "1.是\n2.否"
	read -p "输入数字以选择:" tuntap

	while [[ ! "${tuntap}" =~ ^[1-2]$ ]]
	do
		echo -e "${Error} 无效输入"
		echo -e "${Info} 请重新选择" && read -p "输入数字以选择:" tuntap
	done

	[[ -z "${tuntap}" || "${tuntap}" == "2" ]] && echo -e "${Error} 未开启 tun/tap，请开启后再尝试该脚本 !" && exit 1

	#以下为失败，grep 无效
	#echo -n "`cat /dev/net/tun`" | grep "device"
	#[[ -z "${enable}" ]] && echo -e "${Error} not enable tun/tap !" && exit 1
}

workdir(){
	[[ ! -d /etc/lklhaproxy ]] && mkdir -p /etc/lklhaproxy
	cd /etc/lklhaproxy
}

config(){
	# choose one or many port
	echo -e "${Info} 你想加速单个端口（例如 443）还是端口段(例如 8080-9090) ？\n1.单个端口\n2.端口段"
	read -p "(输入数字以选择):" choose
	while [[ ! "${choose}" =~ ^[1-2]$ ]]
	do
		echo -e "${Error} 无效输入"
		echo -e "${Info} 请重新选择" && read -p "输入数字以选择:" choose
	done

	# download unfully-config-redirect
	[[ ! -f redirect.sh ]] && wget --no-cache -O redirect.sh https://github.com/mzz2017/lkl-haproxy/raw/master/requirement/redirect.sh

	# config: haproxy && redirect
	if [[ "${choose}" == "1" ]]; then
		 echo -e "${Info} 输入你想加速的端口"
		 read -p "(输入单个端口号，例如：443，默认使用 443):" port1
		 [[ -z "${port1}" ]] && port1=443
		 config_haproxy_single_port
		 config_redirect_single_port
	else
		 echo -e "${Info} 输入端口段的第一个端口号"
		 read -p "(例如端口段为 8080-9090，则此处输入 8080，默认使用 8080):" port1
		 [[ -z "${port1}" ]] && port1=8080
		 echo -e "${Info} 输入端口段的第二个端口号"
		 read -p "(例如端口段为 8080-9090，则此处输入 9090，默认使用 9090):" port2
		 [[ -z "${port2}" ]] && port2=9090
		 config_haproxy_ports
		 config_redirect_ports
	fi
}

config_haproxy_single_port(){
echo -e "global

defaults
log global
mode tcp
option dontlognull
option tcpka
timeout connect 5000ms
timeout client 8000s
timeout server 8000s

frontend proxy-in
bind *:${port1}
default_backend proxy-out

backend proxy-out
server server1 10.0.0.1 maxconn 20480\c" > haproxy.cfg
}

config_haproxy_ports(){
echo -e "global

defaults
log global
mode tcp
option dontlognull
option tcpka
timeout connect 5000ms
timeout client 8000s
timeout server 8000s

frontend proxy-in
bind *:${port1}-${port2}
default_backend proxy-out

backend proxy-out
server server1 10.0.0.1 maxconn 20480\c" > haproxy.cfg
}

config_redirect_single_port(){
sed -i "20i\iptables -t nat -I PREROUTING -i $(awk '$2 == 00000000 { print $1 }' /proc/net/route) -p tcp --dport ${port1} -j DNAT --to-destination 10.0.0.2" redirect.sh
}

config_redirect_ports(){
sed -i "20i\iptables -t nat -I PREROUTING -i $(awk '$2 == 00000000 { print $1 }' /proc/net/route) -p tcp --dport ${port1}:${port2} -j DNAT --to-destination 10.0.0.2" redirect.sh
}

check_all(){
	# check config
	[[ ! -f haproxy.cfg ]] && echo -e "${Error} 出错，没有发现 haproxy.cfg !" && exit 1
	[[ ! -f redirect.sh ]] && echo -e "${Error} 出错，没有发现 redirect.sh !" && exit 1

	# check lkl-mod
	[[ ! -f liblkl-hijack.so ]] && wget --no-cache https://github.com/mzz2017/lkl-haproxy/raw/master/mod/liblkl-hijack.so
	[[ ! -f liblkl-hijack.so ]] && echo -e "${Error} 下载 liblkl-hijack.so 失败 !" && exit 1

	# check haproxy
	pkg_install iptables bc
	if [ "`cat /etc/issue | grep -iE "debian"`" ] || [ "`cat /etc/issue | grep -iE "ubuntu"`" ] || ([ -f "/etc/redhat-release" ] && [ "`cat /etc/redhat-release | grep -iE "centos"`" ])
	then
		pkg_install haproxy
	elif [ "`cat /etc/issue | grep -iE "alpine"`" ]
	then
		wget -O ./haproxy https://github.com/mzz2017/lkl-haproxy/raw/master/requirement/alpine/haproxy
		ln -s /etc/lklhaproxy/haproxy /usr/bin/haproxy
	else
		echo -e "不支持的 linux 发行版: $(cut -d\\ -f 1 /etc/issue|head -n 1)"
		exit 1
	fi

	command -v haproxy || (echo -e "${Error} 安装 haproxy 失败 !" && exit 1)

	# check iproute2
	ip tuntap > /dev/null 2>&1 || pkg_install iproute2

	# give privilege
	chmod -R +x /etc/lklhaproxy
}


install(){
	# check wget
	command -v wget > /dev/null 2>&1 || pkg_install wget

	# check curl
	command -v curl > /dev/null 2>&1 || pkg_install curl

	check_system
	check_root
	workdir
	check_ldd
	check_tuntap
	config
	check_all
	enable
	start
	#status
	echo -e "${Info} 已完成，请稍后使用此脚本第二项判断 lkl 是否成功。"
}

status(){
	pingstatus=`ping 10.0.0.2 -c 3 | grep ttl`
	if [[ ! -z "${pingstatus}" ]]; then
		echo -e "${Info} lkl-haproxy 正在运行 !"
		else echo -e "${Error} lkl-haproxy 没有运行 !"
	fi
}

uninstall(){
	check_system
	check_root
	disable
	rm -rf /etc/lklhaproxy
	if [ "`cat /etc/issue | grep -iE "debian"`" ] || [ "`cat /etc/issue | grep -iE "ubuntu"`" ] || ([ -f "/etc/redhat-release" ] && [ "`cat /etc/redhat-release | grep -iE "centos"`" ])
	then
		pkg_uninstall haproxy
	elif [ "`cat /etc/issue | grep -iE "alpine"`" ]
	then
		[ ! -f /usr/bin/haproxy ] && ls /usr/bin/haproxy > /dev/null 2&>1 && rm /usr/bin/haproxy
	else
		echo -e "不支持的 linux 发行版: $(cut -d\\ -f 1 /etc/issue|head -n 1)"
		exit 1
	fi
	#iptables -F
	echo -e "${Info} 请记得重启以停止 lkl bbrplus"
}




echo -e "${Info} 选择你要使用的功能: "
echo -e "1.安装 lkl bbrplus\n2.检查 lkl bbrplus运行状态\n3.卸载 lkl bbrplus"
read -p "输入数字以选择:" function

while [[ ! "${function}" =~ ^[1-3]$ ]]
	do
		echo -e "${Error} 无效输入"
		echo -e "${Info} 请重新选择" && read -p "输入数字以选择:" function
	done

if [[ "${function}" == "1" ]]; then
	install
elif [[ "${function}" == "2" ]]; then
	status
elif [[ "${function}" == "3" ]]; then
	uninstall
else
	echo "${Error} 读取选项失败，可能是因为本脚本不能在当前shell上执行"
fi
