# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-libs/uclibc/uclibc-0.9.30.1-r1.ebuild,v 1.9 2011/04/20 18:10:38 ulm Exp $

EAPI="4"

inherit eutils

MY_P=uClibc-0.9.32
DESCRIPTION="C library for developing embedded Linux systems"
HOMEPAGE="http://www.uclibc.org/"
SRC_URI="http://uclibc.org/downloads/${MY_P}.tar.bz2"

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="-* amd64 x86"
IUSE=""
RESTRICT="strip"

RDEPEND=""
DEPEND=""

S=${WORKDIR}/${MY_P}

src_prepare() {
	epatch "${FILESDIR}"/${P}-BJA-sandbox.patch
	epatch "${FILESDIR}"/${P}-fix_epoll.patch
}

src_configure() {
	cp "${FILESDIR}"/uclibc.config .config
	yes "" 2> /dev/null | make -s oldconfig > /dev/null || die "could not make oldconfig"
}

src_compile() {
	emake headers || die "make headers failed"
	emake || die "make failed"
	emake utils || die "make utils failed"
}

src_install() {
	emake DESTDIR="${D}" install || die "install failed"

	# remove files coming from kernel-headers
	rm -rf "${D}"/usr/include/{linux,asm*}

	emake DESTDIR="${D}" install_utils || die "install-utils failed"
	dobin extra/scripts/getent
	dodoc Changelog* README TODO docs/*.txt DEDICATION.mjn3
}

pkg_postinst() {
	echo "UTC" > "${ROOT}"/etc/TZ
	/sbin/ldconfig
	[[ -x /sbin/telinit ]] && /sbin/telinit U &> /dev/null
}
