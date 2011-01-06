# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sec-policy/selinux-sudo/selinux-sudo-2.20091215.ebuild,v 1.1 2009/12/16 02:54:08 pebenito Exp $

MODS="sudo"
IUSE=""

inherit selinux-policy-2

DESCRIPTION="SELinux policy for sudo"

KEYWORDS="~amd64 ~x86"

POLICY_PATCH="${FILESDIR}/fix-sudo.patch"
