# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sec-policy/selinux-apache/selinux-apache-2.20101213-r1.ebuild,v 1.2 2011/06/02 12:03:36 blueness Exp $
IUSE="kerberos"
MODS="apache"

inherit selinux-policy-2

DESCRIPTION="SELinux policy for Apache HTTPD"
DEPEND="${DEPEND}
	kerberos? ( sec-policy/selinux-kerberos )"
RDEPEND="${DEPEND}"

KEYWORDS="~amd64 ~x86"
S="${WORKDIR}/"

src_unpack() {
	selinux-policy-2_src_unpack
	if ! use kerberos ; then
		[ -z "${POLICY_TYPES}" ] && local POLICY_TYPES="strict targeted mcs mls";
		for i in ${POLICY_TYPES}; do
			sed -i -e "/httpd_keytab_t/d" \
				"${S}/${i}/apache.fc"
		done
	fi
}

pkg_postinst() {
	selinux-policy-2_pkg_postinst
	if use kerberos ; then
		einfo "If you decide to uninstall Kerberos, you should clear the"
		einfo "kerberos use flag here, and then emerge this module again."
		einfo "Failure to do so may result in policy compile errors in the"
		einfo "future."
	else
		einfo "If you install Kerberos later, you should set the kerberos"
		einfo "use flag here, and then emerge this module again in order to"
		einfo "get all of the relevant policy changes.  Failure to do so may"
		einfo "result in errors authenticating against kerberos servers by"
		einfo "Apache."
	fi
}
