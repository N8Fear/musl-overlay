# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-libs/uclibc/uclibc-0.9.30.1-r1.ebuild,v 1.9 2011/04/20 18:10:38 ulm Exp $

EAPI="4"

DESCRIPTION="A new standard library of Linux-based devices"
HOMEPAGE="http://www.etalabs.net/musl/"
SRC_URI="http://www.etalabs.net/musl/releases/${P}.tar.gz"

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="-* ~amd64 ~x86"
IUSE=""
RESTRICT="strip"

RDEPEND=""
DEPEND=""

src_configure() {
	case ${ARCH} in
		x86)
			#do nothing, i386 is the default
			;;
		amd64)
			sed -i -e "s|^ARCH = i386|ARCH = x86_64|" config.mak
			;;
		arm)
			sed -i -e "s|^ARCH = i386|ARCH = arm|" config.mak
			;;
		*)
			eerror "${ARCH} is not supported"
	esac

	sed -i -e "s|^prefix = /usr/local/musl|prefix = /usr|" config.mak
	sed -i -e "s|^exec_prefix = /usr/local|exec_prefix = /usr|" config.mak
	echo "LDFLAGS += -Wl,--hash-style,both" >> config.mak
	echo "CFLAGS += -fno-stack-protector" >> config.mak
}
