# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

inherit toolchain-funcs flag-o-matic eutils

DESCRIPTION="A utility to set the framebuffer videomode"
HOMEPAGE="http://users.telenet.be/geertu/Linux/fbdev/"
SRC_URI="http://users.telenet.be/geertu/Linux/fbdev/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm ~mips ppc x86"
IUSE="static"

DEPEND="sys-devel/bison
	sys-devel/flex"
RDEPEND=""

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}/${P}-build.patch"
	epatch "${FILESDIR}/${P}-musl-compat-and-debian.patch"
}

src_compile() {
	use static && append-ldflags -static
	tc-export CC
	emake || die "emake failed"
}

src_install() {
	dobin fbset modeline2fb con2fbmap || die "dobin failed"
	doman *.[158]
	dodoc etc/fb.modes.* INSTALL
}
