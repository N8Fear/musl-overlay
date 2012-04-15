# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-libs/uclibc/uclibc-0.9.30.1-r1.ebuild,v 1.9 2011/04/20 18:10:38 ulm Exp $

EAPI="4"

MY_P=uClibc-0.9.33-57f058b
MY_PN=uClibc-57f058b
DESCRIPTION="C library for developing embedded Linux systems"
HOMEPAGE="http://www.uclibc.org/"
SRC_URI="http://opensource.dyc.edu/pub/misc/${MY_P}.tar.gz"

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="-* mips"
IUSE=""
RESTRICT="strip"

RDEPEND=""
DEPEND=""

S=${WORKDIR}/${MY_PN}

src_configure() {
	cp "${FILESDIR}"/uclibc-mips.33.config .config || die "could not copy config file"
	yes "" 2> /dev/null | make -s oldconfig > /dev/null || die "could not make oldconfig"
}

src_compile() {
	emake headers
	emake
	emake utils
}

src_install() {
	emake DESTDIR="${D}" install

	# remove files coming from kernel-headers
	rm -rf "${D}"/usr/include/{linux,asm*}

	emake DESTDIR="${D}" install_utils
	dobin extra/scripts/getent
	dodoc Changelog* README TODO docs/*.txt DEDICATION.mjn3
}

pkg_postinst() {
	echo "UTC" > "${ROOT}"/etc/TZ
	/sbin/ldconfig
	[[ -x /sbin/telinit ]] && /sbin/telinit U &> /dev/null
}
