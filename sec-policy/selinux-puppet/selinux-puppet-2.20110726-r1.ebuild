# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI="4"

IUSE=""
MODS="puppet"
POLICY_PATCH="${FILESDIR}/fix-services-puppet-r1.patch"

inherit selinux-policy-2

DESCRIPTION="SELinux policy for puppet"
KEYWORDS="~amd64 ~x86"
