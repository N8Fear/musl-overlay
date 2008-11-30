# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-misc/dhcdbd/dhcdbd-3.0.ebuild,v 1.5 2008/02/29 03:12:57 ranger Exp $

inherit eutils

DESCRIPTION="DHCP D-BUS daemon (dhcdbd) controls dhclient sessions with D-BUS, stores and presents DHCP options."
HOMEPAGE="http://people.redhat.com/dcantrel/dhcdbd"
HOMEPAGE="http://dcantrel.fedorapeople.org/dhcdbd"
SRC_URI="http://dcantrel.fedorapeople.org/dhcdbd/${P}.tar.bz2"

LICENSE="public-domain"
SLOT="0"
KEYWORDS="amd64 ppc ~ppc64 x86"
IUSE="debug"

DEPEND="sys-apps/dbus
	>=net-misc/dhcp-3.0.3-r7"

src_unpack() {
	unpack ${A}
	cd ${S}
	epatch ${FILESDIR}/${PN}-2.5-fixes.patch
	# Create a pidfile immediately after daemonizing so we're more robust
	# with baselayout-2.
	epatch ${FILESDIR}/${PN}-3.0-daemon.patch
	# We don't and won't have dbus snapshots in the tree
	epatch ${FILESDIR}/${PN}-3.0-dbus.patch
	epatch ${FILESDIR}/${PN}-open_missing_mode.patch # Ticket 29
}

src_install() {
	make DESTDIR="${D}" install || die "make install failed"
	dodoc README include/dhcp_options.h
	newinitd ${FILESDIR}/dhcdbd.init dhcdbd
	newconfd ${FILESDIR}/dhcdbd.confd dhcdbd
}

pkg_postinst() {
	einfo "dhcdbd is used by NetworkManager in order to use it"
	einfo "you can add it to runlevels by writing on your terminal"
	einfo "rc-update add dhcdbd default"
}
