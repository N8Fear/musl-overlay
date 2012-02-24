# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-nds/rpcbind/rpcbind-0.2.0.ebuild,v 1.13 2012/01/26 01:02:24 vapier Exp $

EAPI="4"

inherit autotools

SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2"
KEYWORDS="amd64 x86 mips"

DESCRIPTION="portmap replacement which supports RPC over various protocols"
HOMEPAGE="http://sourceforge.net/projects/rpcbind/"

LICENSE="BSD"
SLOT="0"
IUSE="tcpd"

RDEPEND="net-libs/libtirpc
	tcpd? ( sys-apps/tcp-wrappers )"
DEPEND="${RDEPEND}
	dev-util/pkgconfig"

src_prepare() {
	epatch "${FILESDIR}"/${P}-pkgconfig.patch
	epatch "${FILESDIR}"/${P}-uclibc-nss-rpcsvc.patch
	eautoreconf
}

src_configure() {
	econf \
		--bindir=/sbin \
		$(use_enable tcpd libwrap)
}

src_install() {
	emake DESTDIR="${D}" install || die
	doman man/rpc{bind,info}.8
	dodoc AUTHORS ChangeLog NEWS README
	newinitd "${FILESDIR}"/rpcbind.initd rpcbind || die
	newconfd "${FILESDIR}"/rpcbind.confd rpcbind || die
}
