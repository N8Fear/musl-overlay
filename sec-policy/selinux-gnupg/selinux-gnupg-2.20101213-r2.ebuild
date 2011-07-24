# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sec-policy/selinux-gnupg/selinux-gnupg-2.20101213-r1.ebuild,v 1.2 2011/06/02 12:24:44 blueness Exp $

EAPI=3

DESCRIPTION="SELinux policy for GnuPG (meta-package for selinux-gpg)"
HOMEPAGE="http://hardened.gentoo.org/selinux"
SRC_URI=""

LICENSE="as-is"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND=">=sec-policy/selinux-gpg-2.20101213-r2"
