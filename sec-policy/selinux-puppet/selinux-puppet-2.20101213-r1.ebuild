# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sec-policy/selinux-puppet/selinux-puppet-2.20101213.ebuild,v 1.2 2011/06/02 12:49:09 blueness Exp $

IUSE=""

MODS="puppet"

inherit selinux-policy-2

DESCRIPTION="SELinux policy for general applications"

DEPEND=">=sec-policy/selinux-base-policy-2.20101213-r19"
RDEPEND="${DEPEND}"

KEYWORDS="~amd64 ~x86"

POLICY_PATCH="${FILESDIR}/fix-services-puppet-r1.patch"
