# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/gcc/gcc-4.3.3.ebuild,v 1.3 2009/02/24 23:20:55 kumba Exp $

PATCH_VER="1.0"
UCLIBC_VER="1.0"

ETYPE="gcc-compiler"
GCC_FILESDIR="${PORTDIR}/sys-devel/gcc/files"

# Hardened gcc 4 stuff
PIE_VER="10.2.0"
PIE_GCC_VER="4.3.3"
SPECS_VER="0.9.12"
SPECS_GCC_VER="4.3.2"

# arch/libc configurations known to be stable or untested with {PIE,SSP,FORTIFY}-by-default
SSP_STABLE="amd64 x86 ppc ppc64"
SSP_UCLIBC_STABLE=""
PIE_GLIBC_STABLE="x86 amd64 ppc ppc64"
PIE_UCLIBC_STABLE=""
FORTIFY_STABLE="x86 amd64 ppc ppc64"
FORTIFY_UCLIBC_STABLE=""
# Hardened end

inherit toolchain

DESCRIPTION="The GNU Compiler Collection.  Includes C/C++, java compilers, pie+ssp+fortify extensions, Haj Ten Brugge runtime bounds checking"

LICENSE="GPL-2 LGPL-2.1"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~x86-fbsd"

RDEPEND=">=sys-libs/zlib-1.1.4
	>=sys-devel/gcc-config-1.4
	virtual/libiconv
	>=dev-libs/gmp-4.2.1
	>=dev-libs/mpfr-2.3
	!build? (
		gcj? (
			gtk? (
				x11-libs/libXt
				x11-libs/libX11
				x11-libs/libXtst
				x11-proto/xproto
				x11-proto/xextproto
				>=x11-libs/gtk+-2.2
				x11-libs/pango
			)
			>=media-libs/libart_lgpl-2.1
			app-arch/zip
			app-arch/unzip
		)
		>=sys-libs/ncurses-5.2-r2
		nls? ( sys-devel/gettext )
	)"
DEPEND="${RDEPEND}
	test? ( sys-devel/autogen dev-util/dejagnu )
	>=sys-apps/texinfo-4.2-r4
	>=sys-devel/bison-1.875
	amd64? ( >=sys-libs/glibc-2.7-r2 )
	ppc? ( >=${CATEGORY}/binutils-2.17 )
	ppc64? ( >=${CATEGORY}/binutils-2.17 )
	>=${CATEGORY}/binutils-2.17"
PDEPEND=">=sys-devel/gcc-config-1.4"
if [[ ${CATEGORY} != cross-* ]] ; then
	PDEPEND="${PDEPEND} elibc_glibc? ( >=sys-libs/glibc-2.8 )"
fi

src_unpack() {
	gcc_src_unpack

	use vanilla && return 0

	[[ ${CHOST} == ${CTARGET} ]] && epatch "${GCC_FILESDIR}"/gcc-spec-env.patch

	[[ ${CTARGET} == *-softfloat-* ]] && epatch "${GCC_FILESDIR}"/4.3.2/gcc-4.3.2-softfloat.patch

	if use hardened ; then
	    einfo "Hardened toolchain for GCC 4 is made by zorry, psm and xake"
	    einfo "http://forums.gentoo.org/viewtopic-t-668885.html"
	    einfo "https://hardened.gentooexperimental.org/trac/secure"
	    einfo "Thanks KernelOfTruth, dw and everyone else helping testing, suggesting fixes and other things we have missed."
	    einfo "/zorry"
	fi
}
