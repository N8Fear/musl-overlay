# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI="4"

IUSE=""
MODS="consolekit"
POLICY_PATCH="${FILESDIR}/fix-services-consolekit.patch"

inherit selinux-policy-2

DESCRIPTION="SELinux policy for consolekit"

KEYWORDS="~amd64 ~x86"
