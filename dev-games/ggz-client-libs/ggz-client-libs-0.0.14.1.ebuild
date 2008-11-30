# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-games/ggz-client-libs/ggz-client-libs-0.0.14.1.ebuild,v 1.8 2008/10/28 20:32:39 ranger Exp $

inherit games-ggz base

DESCRIPTION="The client libraries for GGZ Gaming Zone"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="alpha amd64 hppa ia64 ppc ~ppc64 sparc x86"
IUSE="debug"

RDEPEND="~dev-games/libggz-${PV}
	dev-libs/expat
	virtual/libintl"
DEPEND="${RDEPEND}
	sys-devel/gettext"

#src_unpack() {
#	unpack "${A}"
#	cd "${S}"
#	epatch "${FILESDIR}"/${PN}-fortify.patch
#}

PATCHES=(  "${FILESDIR}"/"${PN}"-fortify.patch )
