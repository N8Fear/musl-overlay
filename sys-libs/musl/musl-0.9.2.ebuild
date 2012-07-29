# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-libs/uclibc/uclibc-0.9.30.1-r1.ebuild,v 1.9 2011/04/20 18:10:38 ulm Exp $

EAPI="4"

DESCRIPTION="A new standard library of Linux-based devices"
HOMEPAGE="http://www.etalabs.net/musl/"
SRC_URI="http://www.etalabs.net/musl/releases/${P}.tar.gz"

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm ~x86"
IUSE=""
RESTRICT="strip"

RDEPEND=""
DEPEND=""

export CBUILD=${CBUILD:-${CHOST}}
export CTARGET=${CTARGET:-${CHOST}}

do_native_config() {
	einfo "Installing ${PN} as a native C library"
	econf --prefix=/usr --disable-gcc-wrapper
}

do_alternative_config() {
	einfo "Installing ${PN} as an alternative C library"
	econf --prefix=/usr/musl
}

src_configure() {
	if [ ${CTARGET} == ${CHOST} ] ; then
		case ${CHOST} in
			*-musl*) do_native_config ;;
			*) do_alternative_config ;;
		esac
	else
		die "TODO: set up cross compiling"
	fi
}
