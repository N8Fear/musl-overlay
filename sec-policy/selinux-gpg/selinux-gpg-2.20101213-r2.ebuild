# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sec-policy/selinux-gnupg/selinux-gnupg-2.20101213-r1.ebuild,v 1.2 2011/06/02 12:24:44 blueness Exp $

MODS="gpg"
IUSE=""

inherit selinux-policy-2

DESCRIPTION="SELinux policy for GNU privacy guard"

KEYWORDS="amd64 x86"
RDEPEND="!<=sec-policy/selinux-gnupg-2.20101213-r1
	>=sys-apps/policycoreutils-1.30.30
	>=sec-policy/selinux-base-policy-${PV}"

POLICY_PATCH="${FILESDIR}/fix-apps-gpg-r2.patch"
