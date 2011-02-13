# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sec-policy/selinux-wireshark/selinux-wireshark-2.20101213.ebuild,v 1.1 2011/02/05 12:07:15 blueness Exp $

MODS="wireshark"
IUSE=""

inherit selinux-policy-2

DESCRIPTION="SELinux policy for wireshark"

KEYWORDS="~amd64 ~x86"

POLICY_PATCH="${FILESDIR}/fix-apps-wireshark-r1.patch"
