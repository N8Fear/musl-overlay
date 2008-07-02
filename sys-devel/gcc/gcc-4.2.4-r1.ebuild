# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/gcc/gcc-4.2.2.ebuild,v 1.1 2007/10/11 04:46:22 vapier Exp $

PATCH_VER="1.0"
UCLIBC_VER="1.0"
PIE_VER="9.0.10"
PIE_GCC_VER="4.2.0"
#PP_VER="1.0"
#PP_GCC_VER="4.2.0"

#GCC_LIBSSP_SUPPORT="true"
ETYPE="gcc-compiler"

# arch/libc configurations known to be stable with {PIE,SSP,FORTIFY}-by-default
SSP_STABLE="amd64 x86"
SSP_UCLIBC_STABLE=""
PIE_GLIBC_STABLE="amd64 x86"
PIE_UCLIBC_STABLE="x86 arm"
FORTIFY_STABLE="x86 amd64"
FORTIFY_UCLIBC_STABLE=""

# arch/libc configurations known to be broken with {PIE,SSP,FORTIFY}-by-default.
# gcc-4 SSP is only available on FRAME_GROWS_DOWNWARD arches; so it's not
# available on pa, c4x, ia64, alpha, iq2000, m68hc11, stormy16
# (the options are parsed, but they're effectively no-ops).
# rs6000 has special handling to support SSP; ia64 may get the same:
# http://developer.momonga-linux.org/viewvc/trunk/pkgs/gcc4/gcc41-ia64-stack-protector.patch?revision=7447&view=markup&pathrev=7447
SSP_UNSUPPORTED="hppa sh ia64 alpha ppc sparc mips ppc64 m68k"
SSP_UCLIBC_UNSUPPORTED="${SSP_UNSUPPORTED} amd64 x86 arm"
PIE_UCLIBC_UNSUPPORTED="alpha amd64 hppa ia64 m68k ppc64 s390 sh sparc"
PIE_GLIBC_UNSUPPORTED="hppa"
FORTIFY_UNSUPPORTED="ppc sparc ppc64 mips arm alpha sh ia64 m68k s390 hppa"
FORTIFY_UCLIBC_UNSUPPORTED="${FORTIFY_UNSUPPORTED} x86 amd64"


# This patch is obsoleted by stricter control over how one builds a hardened
# compiler from a vanilla compiler.  By forbidding changing from normal to
# hardened between gcc stages, this is no longer necessary.
GENTOO_PATCH_EXCLUDE="51_all_gcc-3.4-libiberty-pic.patch"

inherit toolchain

DESCRIPTION="The GNU Compiler Collection.  Includes C/C++, java compilers, pie+ssp extensions, Haj Ten Brugge runtime bounds checking"

LICENSE="GPL-2 LGPL-2.1"
KEYWORDS="~alpha ~amd64 ~hppa ~ia64 ~ppc -ppc64 ~sparc ~sparc-fbsd ~x86 ~x86-fbsd" #ppc64: 179218

RDEPEND=">=sys-libs/zlib-1.1.4
	|| ( >=sys-devel/gcc-config-1.3.12-r4 )
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
		)
		>=sys-libs/ncurses-5.2-r2
		nls? ( sys-devel/gettext )
	)"
# Hardened gcc builds with SSP enabled on itself, so requires a
# gcc-4-SSP-compatible glibc installed, from gcc's stage1 onwards.
# We assume uclibc users know what they're doing.
DEPEND="${RDEPEND}
	hardened? ( elibc_glibc? ( >=sys-libs/glibc-2.6.1 ) )
	test? ( sys-devel/autogen dev-util/dejagnu )
	>=sys-apps/texinfo-4.2-r4
	>=sys-devel/bison-1.875
	ppc? ( >=${CATEGORY}/binutils-2.17 )
	ppc64? ( >=${CATEGORY}/binutils-2.17 )
	>=${CATEGORY}/binutils-2.15.94"
PDEPEND="|| ( sys-devel/gcc-config )"
if [[ ${CATEGORY} != cross-* ]] ; then
	PDEPEND="${PDEPEND} elibc_glibc? ( >=sys-libs/glibc-2.6.1 )"
fi

src_unpack() {
	gcc_src_unpack
	
	use vanilla && return 0

	[[ ${CHOST} == ${CTARGET} ]] && epatch "${FILESDIR}"/gcc-spec-env.patch

	[[ ${CTARGET} == *-softfloat-* ]] && epatch "${FILESDIR}"/4.0.2/gcc-4.0.2-softfloat.patch
	
	einfo "Hardened toolchain for GCC 4 is made by kevquinn, psm, zorry and xake"
	einfo "http://forum.gentoo.org/viewtopic-t-668885.html"
	einfo "https://hardened.gentooexperimental.org/secure"
	einfo "Thanx for the help from the forum thread and #friendly-coders #gentoo-hardened @freenode.net"
	einfo "/zorry"
}