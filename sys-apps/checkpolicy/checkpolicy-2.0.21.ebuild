# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/checkpolicy/checkpolicy-2.0.19.ebuild,v 1.1 2009/08/02 01:17:05 pebenito Exp $

IUSE="debug"

inherit eutils

SEPOL_VER="2.0.41"
SEMNG_VER="2.0.45"

DESCRIPTION="SELinux policy compiler"
HOMEPAGE="http://userspace.selinuxproject.org"
SRC_URI="http://userspace.selinuxproject.org/releases/20100525/devel/${P}.tar.gz"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"

DEPEND=">=sys-libs/libsepol-${SEPOL_VER}
	>=sys-libs/libsemanage-${SEMNG_VER}
	sys-devel/flex
	sys-devel/bison"

RDEPEND=">=sys-libs/libsemanage-${SEMNG_VER}"

src_compile() {
	emake YACC="bison -y" || die
}

src_install() {
	make DESTDIR="${D}" install

	if useq debug; then
		dobin "${S}/test/dismod"
		dobin "${S}/test/dispol"
	fi
}

pkg_postinst() {
	einfo "This checkpolicy can compile version `checkpolicy -V |cut -f 1 -d ' '` policy."
}
