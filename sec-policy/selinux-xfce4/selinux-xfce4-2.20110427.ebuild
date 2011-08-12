# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sec-policy/selinux-courier-imap/selinux-courier-imap-2.20101213-r1.ebuild,v 1.2 2011/06/02 12:12:36 blueness Exp $

EAPI=4

DESCRIPTION="SELinux policy for xfce4"
HOMEPAGE="http://hardened.gentoo.org"
SRC_URI=""

LICENSE="as-is"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND=">=sec-policy/selinux-base-policy-2.20110726-r1"

pkg_postinst() {
	elog "selinux-xfce4 is not needed anymore. All its functionality has been"
	elog "included in the base policy since 2.20110726-r1."
}
