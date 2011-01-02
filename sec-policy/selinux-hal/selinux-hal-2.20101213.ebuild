# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sec-policy/selinux-hal/selinux-hal-2.20091215.ebuild,v 1.1 2009/12/16 02:53:33 pebenito Exp $

IUSE=""

MODS="hal dmidecode"

inherit selinux-policy-2

RDEPEND="sec-policy/selinux-dbus"

DESCRIPTION="SELinux policy for desktops"

KEYWORDS="~amd64 ~x86"
