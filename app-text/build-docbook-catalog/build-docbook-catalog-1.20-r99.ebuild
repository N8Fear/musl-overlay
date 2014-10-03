# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-text/build-docbook-catalog/build-docbook-catalog-1.20.ebuild,v 1.5 2014/02/11 20:25:32 grobian Exp $

EAPI=5

inherit eutils

DESCRIPTION="DocBook XML catalog auto-updater"
HOMEPAGE="http://sources.gentoo.org/gentoo-src/build-docbook-catalog/"
SRC_URI="mirror://gentoo/${P}.tar.xz
	http://dev.gentoo.org/~floppym/distfiles/${P}.tar.xz
	http://dev.gentoo.org/~vapier/dist/${P}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~mips ~x86"
IUSE=""

RDEPEND="|| ( sys-apps/util-linux app-misc/getopt )
	!<app-text/docbook-xsl-stylesheets-1.73.1
	dev-libs/libxml2"
DEPEND=""

pkg_setup() {
	# export for bug #490754
	export MAKEOPTS+=" EPREFIX=${EPREFIX}"
}

src_prepare() {
	sed -i -e "/^EPREFIX=/s:=.*:='${EPREFIX}':" build-docbook-catalog || die
	has_version sys-apps/util-linux || sed -i -e '/^GETOPT=/s/getopt/&-long/' build-docbook-catalog || die
	use elibc_musl && epatch "${FILESDIR}"/${PN}-remove-getopt-long.patch
}

pkg_postinst() {
	# New version -> regen files
	build-docbook-catalog
}
