#!/bin/sh
# utf-8 coding

#
# ����dhcp6s�ű���llm
# ����cfm��������dhcp6s.conf��Ȼ������dhcp6s
# ipv6.lan.addr=2001::1
# ipv6.lan.prefix=2001::
# ipv6.lan.prefix_len=64
# ipv6.lan.auto_dns=1
# ipv6.lan.dns1=2001:12bb::1
# ipv6.lan.dns2=2001:12bb::2
# 
# ipv6.lan.d6s.enable=1
# ipv6.lan.d6s.stateless=1
# ipv6.lan.d6start_addr=100
# ipv6.lan.d6end_addr=200

# ipv6.wan.pd_prefix=::
# ipv6.wan.pd_prefix_len=64

LAN_IFNAME=$1

if [[ -z ${LAN_IFNAME} ]]; then
    LAN_IFNAME="br0"
    echo "default lan ifname br0"    
fi


CONFIG_PATH=/etc/dhcp6s.conf
IA_PD=`cfm get ipv6.wan.d6c.iapd`
LAN_ADDR=`cfm get ipv6.lan.addr`
LAN_ADDR_PREFIX_LEN=`cfm get ipv6.lan.addr_prefix_len`
LAN_PREFIX=`cfm get ipv6.lan.prefix`
LAN_PREFIX_LEN=`cfm get ipv6.lan.prefix_len`
LAN_AUTO_DNS=`cfm get ipv6.lan.auto_dns`
LAN_DNS1=`cfm get ipv6.lan.dns1`
LAN_DNS2=`cfm get ipv6.lan.dns2`
DHCP6S_ENABLE=`cfm get ipv6.lan.d6s.enable`
DHCP6S_STATELESS=`cfm get ipv6.lan.d6s.stateless`
DHCP6S_POOL_START=`cfm get ipv6.lan.d6start_addr`
DHCP6S_POOL_END=`cfm get ipv6.lan.d6end_addr`

# �������ǰ׺�����µ�ǰ׺��/var/ipv6_wan_status
WAN_PD_PREFIX=`cfm get ipv6.wan.pd_prefix`
WAN_PD_PREFIX_LEN=`cfm get ipv6.wan.pd_prefix_len`

WAN_AUTO_DNS=`cfm get ipv6.wan.auto_dns`
WAN_DNS1=`cfm get ipv6.wan.dns1`
WAN_DNS2=`cfm get ipv6.wan.dns2`

# ���WANû�п���ǰ׺�������ֶ�����LAN��ַ��

if [ "${IA_PD}" == "1" ]; then
    LAN_PREFIX=${WAN_PD_PREFIX}
fi


# ������Զ�DNS������resolv6.conf���DNS���������ֶ�DNS
if [ "${LAN_AUTO_DNS}" == "1" ]; then
    if [ "${WAN_AUTO_DNS}" == "0" ]; then
        DNS="${WAN_DNS1} ${WAN_DNS2}"
    else
        DNS_TMP=`cat /etc/resolv6.conf | grep ":" | awk '{print $2}'`
        # ����תΪһ��
        for item in $DNS_TMP
        do
            DNS="${DNS} ${item}"
        done
    fi
else
    DNS="${LAN_DNS1} ${LAN_DNS2}"
fi


# ��ʼд�����ļ�
echo "# dhcp6s config file"                                  > ${CONFIG_PATH}
echo "option domain-name-servers ${DNS};"                    >> ${CONFIG_PATH}

# �������״̬�������õ�ַ��
if [ "${DHCP6S_STATELESS}" == "0" ]; then
    echo "interface ${LAN_IFNAME}{"                         >> ${CONFIG_PATH}
    echo "    address-pool pool1 3600 7200; "               >> ${CONFIG_PATH}
    echo "};"                                               >> ${CONFIG_PATH}
    echo ""                                                 >> ${CONFIG_PATH}
    echo "pool pool1{"                                      >> ${CONFIG_PATH}
    echo "    range ${LAN_PREFIX}${DHCP6S_POOL_START} \
to ${LAN_PREFIX}${DHCP6S_POOL_END}; "                       >> ${CONFIG_PATH}
    echo "};"                                               >> ${CONFIG_PATH}
fi


killall -9 dhcp6s
dhcp6s ${LAN_IFNAME} -d  &
