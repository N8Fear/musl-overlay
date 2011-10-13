# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sec-policy/selinux-mozilla/selinux-mozilla-2.20110726-r2.ebuild,v 1.1 2011/09/17 16:20:16 swift Exp $
EAPI="4"

IUSE=""
MODS="mozilla"
BASEPOL="2.20110726-r5"

inherit selinux-policy-2

DESCRIPTION="SELinux policy for mozilla"
KEYWORDS="~amd64 ~x86"
