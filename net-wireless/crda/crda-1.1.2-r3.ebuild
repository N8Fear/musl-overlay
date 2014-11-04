# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-wireless/crda/crda-1.1.2-r3.ebuild,v 1.11 2013/01/01 08:27:28 ago Exp $

EAPI=4
inherit eutils toolchain-funcs python

DESCRIPTION="Central Regulatory Domain Agent for wireless networks."
HOMEPAGE="http://wireless.kernel.org/en/developers/Regulatory"
SRC_URI="http://linuxwireless.org/download/crda/${P}.tar.bz2"

LICENSE="ISC"
SLOT="0"
KEYWORDS="amd64 arm ~mips ppc x86"
IUSE=""

RDEPEND="dev-libs/openssl
	dev-libs/libnl
	net-wireless/wireless-regdb"
DEPEND="${RDEPEND}
	dev-python/m2crypto
	=dev-lang/python-2*
	virtual/pkgconfig"
RDEPEND="${RDEPEND}
	>=virtual/udev-171"

src_prepare() {
	epatch "${FILESDIR}"/libnl31-support.diff
	epatch "${FILESDIR}"/${P}-missing-include.patch

	python_convert_shebangs 2 utils/key2pub.py

	sed -i \
		-e "s:\<pkg-config\>:$(tc-getPKG_CONFIG):" \
		Makefile || die
}

src_compile() {
	emake UDEV_RULE_DIR=/lib/udev/rules.d/ REG_BIN=/usr/$(get_libdir)/crda/regulatory.bin USE_OPENSSL=1 CC="$(tc-getCC)" all_noverify
}

src_test() {
	emake USE_OPENSSL=1 CC="$(tc-getCC)" verify
}

src_install() {
	emake UDEV_RULE_DIR=/lib/udev/rules.d/ REG_BIN=/usr/$(get_libdir)/crda/regulatory.bin USE_OPENSSL=1 DESTDIR="${D}" install
	keepdir /etc/wireless-regdb/pubkeys
}
