# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sec-policy/selinux-postfix/selinux-postfix-2.20101213.ebuild,v 1.1 2011/02/05 12:07:12 blueness Exp $

MODS="sasl"
IUSE=""

inherit selinux-policy-2

DESCRIPTION="SELinux policy for sasl"

KEYWORDS="~amd64 ~x86"

POLICY_PATCH="${FILESDIR}/fix-services-sasl-r1.patch"
