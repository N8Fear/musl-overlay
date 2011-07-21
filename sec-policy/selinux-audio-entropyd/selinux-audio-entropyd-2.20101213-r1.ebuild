# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sec-policy/selinux-audio-entropyd/selinux-audio-entropyd-2.20101213.ebuild,v 1.2 2011/06/02 12:05:20 blueness Exp $

MODS="audioentropy"
IUSE=""

inherit selinux-policy-2

DESCRIPTION="SELinux policy for entropy-managing domains like audioentropyd, haveged, etc."

KEYWORDS="~amd64 ~x86"
RDEPEND="!<=sec-policy/selinux-haveged-2.20101213-r1
	>=sys-apps/policycoreutils-1.30.30
	>=sec-policy/selinux-base-policy-${PV}"

POLICY_PATCH="${FILESDIR}/fix-services-audioentropy-r1.patch"
