# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="4"

inherit eutils

DESCRIPTION="Time and memory-efficiency tests of various C/POSIX standard library functions"
HOMEPAGE="http://www.etalabs.net/libc-bench.html"
SRC_URI="http://www.etalabs.net/releases/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

src_prepare() {
	epatch "${FILESDIR}"/respect-flags.patch
}

src_install() {
	exeinto /usr/bin
	doexe libc-bench
}
