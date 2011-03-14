# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sec-policy/selinux-openldap/selinux-openldap-2.20101213.ebuild,v 1.1 2011/02/05 12:07:07 blueness Exp $

MODS="ldap"
IUSE=""

inherit selinux-policy-2

DESCRIPTION="SELinux policy for OpenLDAP server"
RDEPEND="!<=sec-policy/selinux-openldap-2.20101213
        >=sys-apps/policycoreutils-1.30.30
		>=sec-policy/selinux-base-policy-${PV}"

KEYWORDS="~amd64 ~x86"

POLICY_PATCH="${FILESDIR}/fix-services-ldap-r1.patch"
