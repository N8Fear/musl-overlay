# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI="4"

IUSE=""
MODS="ftp"

inherit selinux-policy-2

DESCRIPTION="SELinux policy for ftp"
KEYWORDS="~amd64 ~x86"
DEPEND="=sec-policy/selinux-base-policy-2.20110726-r1
	!<sec-policy/selinux-ftpd-2.20110726"
