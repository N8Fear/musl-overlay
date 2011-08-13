# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI="4"

IUSE=""
MODS="dkim"
DEPEND=">=sec-policy/selinux-base-policy-2.20110726-r1
	>=sec-policy/selinux-milter-2.20110726"

inherit selinux-policy-2

DESCRIPTION="SELinux policy for dkim"

KEYWORDS="~amd64 ~x86"
