# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI="4"

IUSE=""
MODS="apm"

inherit selinux-policy-2

DESCRIPTION="SELinux policy for apm"
KEYWORDS="~amd64 ~x86"
DEPEND="=sec-policy/selinux-base-policy-2.20110726-r1
	!<sec-policy/selinux-acpi-2.20110726"