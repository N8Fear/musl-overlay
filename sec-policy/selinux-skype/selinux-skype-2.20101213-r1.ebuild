# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sec-policy/selinux-acpi/selinux-acpi-2.20091215.ebuild,v 1.1 2009/12/16 02:53:59 pebenito Exp $

IUSE=""

MODS="skype"

inherit selinux-policy-2

DESCRIPTION="SELinux policy for general applications"

KEYWORDS="~amd64 ~x86"

POLICY_PATCH="${FILESDIR}/add-apps-skype.patch"
RDEPEND=">=sec-policy/selinux-base-policy-2.20101213-r4"
