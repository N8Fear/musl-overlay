# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/virtual/libc/libc-0.ebuild,v 1.4 2012/04/27 23:16:17 aballier Exp $

EAPI=1

DESCRIPTION="Virtual for the C library"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0"
KEYWORDS="~amd64 ~arm" 
IUSE=""

DEPEND=""
# explicitly depend on SLOT 2.2 of glibc, because it sets
# a different SLOT for cross-compiling
RDEPEND="!prefix? (
		elibc_glibc? ( sys-libs/glibc:2.2 )
		elibc_uclibc? ( sys-libs/uclibc )
		elibc_musl? ( sys-libs/musl )
		elibc_FreeBSD? ( sys-freebsd/freebsd-lib )
	)"
