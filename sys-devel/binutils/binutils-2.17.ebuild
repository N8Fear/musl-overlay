# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/binutils/binutils-2.17.ebuild,v 1.22 2007/06/25 07:43:30 opfer Exp $

PATCHVER="1.2"
UCLIBC_PATCHVER="1.0"
ELF2FLT_VER=""
inherit toolchain-binutils

# ARCH - packages to test before marking
KEYWORDS="-* alpha amd64 arm ~hppa ia64 mips ppc ppc64 sh sparc ~sparc-fbsd x86 ~x86-fbsd"
