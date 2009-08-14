# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/gcc/gcc-4.3.4-r1.ebuild,v 1.2 2009/08/10 03:00:00 zorry Exp $

# Fixed in 4.3.4 and should be removed from the patchset
GENTOO_PATCH_EXCLUDE="69_all_gcc43-pr39013.patch" #262567

PATCH_VER="1.0"
UCLIBC_VER="1.0"

ETYPE="gcc-compiler"
GCC_FILESDIR="${PORTDIR}/sys-devel/gcc/files"

# Hardened gcc 4 stuff
ESPF_VER="0.3.3"
SPECS_VER="0.1.5"

# arch/libc configurations known to be stable or untested with {PIE,SSP,FORTIFY}-by-default
ESPF_GLIBC_SUPPORT="amd64 x86 ppc ppc64 arm sparc sparc64"
ESPF_UCLIBC_SUPPORT="x86 arm"
# Hardened end

inherit toolchain

DESCRIPTION="The GNU Compiler Collection.  Includes C/C++, java compilers, pie+ssp extensions, Haj Ten Brugge runtime bounds checking"

LICENSE="GPL-3 LGPL-2.1 libgcc libstdc++"
KEYWORDS="~amd64 ~arm -hppa ~ppc ~ppc64 ~x86 -x86-fbsd"

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
	sys-devel/flex
	elibc_glibc? ( >=sys-libs/glibc-2.8 )
	amd64? ( multilib? ( gcj? ( app-emulation/emul-linux-x86-xlibs ) ) )
	ppc? ( >=${CATEGORY}/binutils-2.17 )
	ppc64? ( >=${CATEGORY}/binutils-2.17 )
	>=${CATEGORY}/binutils-2.15.94"
PDEPEND=">=sys-devel/gcc-config-1.4"
if [[ ${CATEGORY} != cross-* ]] ; then
	PDEPEND="${PDEPEND} elibc_glibc? ( >=sys-libs/glibc-2.8 )"
fi

src_unpack() {
	gcc_src_unpack

	use vanilla && return 0

	sed -i 's/use_fixproto=yes/:/' gcc/config.gcc #PR33200

	[[ ${CHOST} == ${CTARGET} ]] && epatch "${GCC_FILESDIR}"/gcc-spec-env.patch

	[[ ${CTARGET} == *-softfloat-* ]] && epatch "${GCC_FILESDIR}"/4.3.2/gcc-4.3.2-softfloat.patch

	if use hardened ; then
		einfo "Hardened toolchain for GCC 4.4 is made by Zorry, Blueness and Xake "
		einfo "http://forums.gentoo.org/viewtopic-t-668885.html"
		einfo "http://hardened.gentooexperimental.org/trac/secure"
		einfo "Thanks KernelOfTruth, dw and everyone else helping testing,"
		einfo "suggesting fixes and other things we have missed."
		einfo "/zorry"
	fi
}
