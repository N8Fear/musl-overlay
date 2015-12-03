# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="4"

inherit eutils toolchain-funcs flag-o-matic systemd

DESCRIPTION="A software watchdog and /dev/watchdog daemon"
HOMEPAGE="http://sourceforge.net/projects/watchdog/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm ~mips ppc x86"
IUSE="nfs"

DEPEND="nfs? ( net-libs/libtirpc )"
RDEPEND="${DEPEND}"

src_prepare() {
	epatch "${FILESDIR}/${PN}-5.14-fix-build-with-musl.patch"
}

src_configure() {
	if use nfs ; then
		tc-export PKG_CONFIG
		append-cppflags $(${PKG_CONFIG} libtirpc --cflags)
		export LIBS+=" $(${PKG_CONFIG} libtirpc --libs)"
	fi
	econf $(use_enable nfs)
}

src_install() {
	default
	docinto examples
	dodoc examples/*

	newconfd "${FILESDIR}"/${PN}-conf.d ${PN}
	newinitd "${FILESDIR}"/${PN}-init.d ${PN}
	systemd_dounit "${FILESDIR}"/watchdog.service
}
