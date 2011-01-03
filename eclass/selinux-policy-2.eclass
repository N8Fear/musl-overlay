# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/selinux-policy-2.eclass,v 1.4 2009/08/02 02:58:25 pebenito Exp $

# Eclass for installing SELinux policy, and optionally
# reloading the reference-policy based modules.

inherit eutils

IUSE=""

HOMEPAGE="http://www.gentoo.org/proj/en/hardened/selinux/"
SRC_URI="http://oss.tresys.com/files/refpolicy/refpolicy-${PV}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
S="${WORKDIR}/"

RDEPEND=">=sys-apps/policycoreutils-1.30.30
	>=sec-policy/selinux-base-policy-${PV}
	${MODDEPEND}"

DEPEND="${RDEPEND}
	sys-devel/m4
	>=sys-apps/checkpolicy-1.30.12"

selinux-policy-2_src_unpack() {
	local modfiles
	[ -z "${POLICY_TYPES}" ] && local POLICY_TYPES="strict targeted"

	unpack ${A}

	for i in ${MODS}; do
		modfiles="`find ${S}/refpolicy/policy/modules -iname $i.te` $modfiles"
		modfiles="`find ${S}/refpolicy/policy/modules -iname $i.fc` $modfiles"
	done

	for i in ${POLICY_TYPES}; do
		mkdir "${S}"/${i}
		cp "${S}"/refpolicy/doc/Makefile.example "${S}"/${i}/Makefile

		cp ${modfiles} "${S}"/${i}

		if [ -n "${POLICY_PATCH}" ]; then
			for POLPATCH in "${POLICY_PATCH}";
			do
				cd "${S}"/${i}
				einfo "Patching ${i}"
				epatch "${POLPATCH}" || die "failed patch ${POLPATCH}"
			done
		fi

	done
}

selinux-policy-2_src_compile() {
	[ -z "${POLICY_TYPES}" ] && local POLICY_TYPES="strict targeted"

	for i in ${POLICY_TYPES}; do
		make NAME=$i -C "${S}"/${i} || die "${i} compile failed"
	done
}

selinux-policy-2_src_install() {
	[ -z "${POLICY_TYPES}" ] && local POLICY_TYPES="strict targeted"
	local BASEDIR="/usr/share/selinux"

	for i in ${POLICY_TYPES}; do
		for j in ${MODS}; do
			echo "Installing ${i} ${j} policy package"
			insinto ${BASEDIR}/${i}
			doins "${S}"/${i}/${j}.pp
		done
	done
}

selinux-policy-2_pkg_postinst() {
	# build up the command in the case of multiple modules
	local COMMAND
	for i in ${MODS}; do
		COMMAND="-i ${i}.pp ${COMMAND}"
	done
	[ -z "${POLICY_TYPES}" ] && local POLICY_TYPES="strict targeted"

	for i in ${POLICY_TYPES}; do
		einfo "Inserting the following modules into the $i module store: ${MODS}"

		cd /usr/share/selinux/${i}
		semodule -s ${i} ${COMMAND}
	done
}

EXPORT_FUNCTIONS src_unpack src_compile src_install pkg_postinst
