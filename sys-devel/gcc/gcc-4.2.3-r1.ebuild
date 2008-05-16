# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/gcc/gcc-4.2.0.ebuild,v 1.1 2007/05/19 03:22:33 vapier Exp $

PATCH_VER="1.0"
UCLIBC_VER="1.0"
PIE_VER="9.0.9"
PIE_GCC_VER="4.2.0"
#PP_VER="1.0"
#PP_GCC_VER="4.2.0"


ETYPE="gcc-compiler"

# arch/libc configurations known to be stable with {PIE,SSP}-by-default
SSP_STABLE="amd64 x86"
SSP_UCLIBC_STABLE="ppc sparc x86"
PIE_GLIBC_STABLE="amd64 ppc ppc64 sparc x86"
PIE_UCLIBC_STABLE="mips ppc x86"

# arch/libc configurations known to be broken with {PIE,SSP}-by-default.
# gcc-4 SSP is only available on FRAME_GROWS_DOWNWARD arches; so it's not
# available on pa, c4x, ia64, alpha, iq2000, m68hc11, stormy16
# (the options are parsed, but they're effectively no-ops).
# rs6000 has special handling to support SSP; ia64 may get the same:
# http://developer.momonga-linux.org/viewvc/trunk/pkgs/gcc4/gcc41-ia64-stack-protector.patch?revision=7447&view=markup&pathrev=7447
SSP_UNSUPPORTED="hppa sh ia64 alpha"
SSP_UCLIBC_UNSUPPORTED="${SSP_UNSUPPORTED}"
PIE_UCLIBC_UNSUPPORTED="alpha amd64 arm hppa ia64 m68k ppc64 s390 sh sparc"
PIE_GLIBC_UNSUPPORTED="hppa"

# This patch is obsoleted by stricter control over how one builds a hardened
# compiler from a vanilla compiler.  By forbidding changing from normal to
# hardened between gcc stages, this is no longer necessary.
GENTOO_PATCH_EXCLUDE="51_all_gcc-3.4-libiberty-pic.patch"


# whether we should split out specs files for multiple {PIE,SSP}-by-default
# and vanilla configurations.
#SPLIT_SPECS=no #${SPLIT_SPECS-true} hard disable until #106690 is fixed
SPLIT_SPECS=${SPLIT_SPECS-true}

inherit toolchain

DESCRIPTION="The GNU Compiler Collection.  Includes C/C++, java compilers, pie+ssp extensions, Haj Ten Brugge runtime bounds checking"

LICENSE="GPL-2 LGPL-2.1"
KEYWORDS="~x86 ~amd64"

RDEPEND=">=sys-libs/zlib-1.1.4
	>=sys-devel/gcc-config-1.4
	virtual/libiconv
	fortran? (
		>=dev-libs/gmp-4.2.1
		>=dev-libs/mpfr-2.2.0_p10
	)
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
# Hardened gcc builds with SSP enabled on itself, so requires a
# gcc-4-SSP-compatible glibc installed, from gcc's stage1 onwards.
# We assume uclibc users know what they're doing.
DEPEND="${RDEPEND}
	test? ( sys-devel/autogen dev-util/dejagnu )
	hardened? ( elibc_glibc? ( >=sys-libs/glibc-2.6.1 ) )
	>=sys-apps/texinfo-4.2-r4
	>=sys-devel/bison-1.875
	ppc? ( >=${CATEGORY}/binutils-2.17 )
	ppc64? ( >=${CATEGORY}/binutils-2.17 )
	>=${CATEGORY}/binutils-2.15.94"
PDEPEND=">=sys-devel/gcc-config-1.4"
if [[ ${CATEGORY} != cross-* ]] ; then
	PDEPEND="${PDEPEND} elibc_glibc? ( >=sys-libs/glibc-2.6.1 )"
fi

src_unpack() {
	gcc_src_unpack

	use vanilla && return 0

	[[ ${CHOST} == ${CTARGET} ]] && epatch "${FILESDIR}"/gcc-spec-env.patch

	[[ ${CTARGET} == *-softfloat-* ]] && epatch "${FILESDIR}"/4.0.2/gcc-4.0.2-softfloat.patch

	# Add the crtbeginTS.o file - used for "static PIE" links
	epatch "${FILESDIR}"/4.2.0/gcc-4.2.0-crtbeginTS.patch
	# Ensure crtfiles are built fno-PIC/fPIC as appropriate, not fPIE
	epatch "${FILESDIR}"/4.1.1/gcc-4.1.1-nopie-crtstuff.patch
}
