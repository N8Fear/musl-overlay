# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI="4"

IUSE=""
MODS="sasl"

inherit selinux-policy-2

DESCRIPTION="SELinux policy for sasl"
DEPEND="=sec-policy/selinux-base-policy-2.20110726-r1
	!<sec-policy/selinux-cyrus-sasl-2.20110726"
KEYWORDS="~amd64 ~x86"