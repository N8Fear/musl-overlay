# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sec-policy/selinux-inetd/selinux-inetd-2.20110726-r1.ebuild,v 1.1 2011/11/15 10:45:18 swift Exp $
EAPI="4"

IUSE=""
MODS="inetd"
BASEPOL="2.20110726-r7"

inherit selinux-policy-2

DESCRIPTION="SELinux policy for inetd"

KEYWORDS="~amd64 ~x86"
