# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI="4"

IUSE=""
MODS="rpc"
BASEPOL="2.20110726-r1"

inherit selinux-policy-2

DESCRIPTION="SELinux policy for rpc"
KEYWORDS="~amd64 ~x86"
RDEPEND="!<sec-policy/selinux-nfs-2.20110726"
