# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: Exp $

IUSE=""

MODS="virt"

inherit selinux-policy-2

DESCRIPTION="SELinux policy for libvirtd"

KEYWORDS="~amd64 ~x86"

src_install() {
	selinux-policy-2_src_install
	[ -z "${POLICY_TYPES}" ] && local POLICY_TYPES="strict targeted"
	for i in ${POLICY_TYPES}; do
		mkdir -p ${D}/etc/selinux/${i}/contexts
		echo "system_u:system_r:svirt_t" >${D}/etc/selinux/${i}/contexts/virtual_domain_context
		echo "system_u:object_r:svirt_image_t" >${D}/etc/selinux/${i}/contexts/virtual_image_context
		echo "system_u:object_r:virt_content_t" >>${D}/etc/selinux/${i}/contexts/virtual_image_context
	done
}
