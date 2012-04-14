# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-libs/uclibc/uclibc-0.9.30.1-r1.ebuild,v 1.9 2011/04/20 18:10:38 ulm Exp $

EAPI="4"

inherit savedconfig

MY_P=uClibc-${PV}
DESCRIPTION="C library for developing embedded Linux systems"
HOMEPAGE="http://www.uclibc.org/"
SRC_URI="http://uclibc.org/downloads/${MY_P}.tar.bz2"

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="-* amd64 x86 mips ~ppc"
IUSE=""
RESTRICT="strip"

RDEPEND=""
DEPEND=""

S=${WORKDIR}/${MY_P}

src_configure() {
	if use savedconfig; then
		restore_config config/.config
	else
		cp "${FILESDIR}"/uclibc-${ARCH}.${PV}.config .config || die "${ARCH} is not supported"
	fi
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

	if use savedconfig; then
		save_config config/.config
	fi
}

pkg_postinst() {
	echo "UTC" > "${ROOT}"/etc/TZ
	/sbin/ldconfig
	[[ -x /sbin/telinit ]] && /sbin/telinit U &> /dev/null
}
