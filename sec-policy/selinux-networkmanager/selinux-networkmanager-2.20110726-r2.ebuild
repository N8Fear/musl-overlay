# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sec-policy/selinux-networkmanager/selinux-networkmanager-2.20110726-r1.ebuild,v 1.2 2011/10/23 12:42:33 swift Exp $
EAPI="4"

IUSE=""
MODS="networkmanager"
BASEPOL="2.20110726-r7"

inherit selinux-policy-2

DESCRIPTION="SELinux policy for networkmanager"
KEYWORDS="~amd64 ~x86"
