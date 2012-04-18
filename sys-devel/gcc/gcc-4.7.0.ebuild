# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/gcc/gcc-4.7.0.ebuild,v 1.0 2012/01/17 19:02:25 zorry Exp $

PATCH_VER="1.1"
UCLIBC_VER="1.0"

# Hardened gcc 4 stuff
PIE_VER="0.5.3"
SPECS_VER="0.2.0"
SPECS_GCC_VER="4.4.3"
# arch/libc configurations known to be stable with {PIE,SSP}-by-default
PIE_GLIBC_STABLE="x86 amd64 ppc ppc64 arm ia64"
PIE_UCLIBC_STABLE="x86 arm amd64 ppc ppc64"
SSP_STABLE="amd64 x86 ppc ppc64 arm"
# uclibc need tls and nptl support for SSP support
# uclibc 0.9.32 or newer.
SSP_UCLIBC_STABLE="x86 amd64 ppc pcc64"
#end Hardened stuff

inherit toolchain

DESCRIPTION="The GNU Compiler Collection"

LICENSE="GPL-3 LGPL-3 || ( GPL-3 libgcc libstdc++ gcc-runtime-library-exception-3.1 ) FDL-1.2"
KEYWORDS=""

RDEPEND=""
DEPEND="${RDEPEND}
	elibc_glibc? ( >=sys-libs/glibc-2.12 )
	amd64? ( multilib? ( gcj? ( app-emulation/emul-linux-x86-xlibs ) ) )
	>=${CATEGORY}/binutils-2.18"
PDEPEND="go? ( >=sys-devel/gcc-config-1.5 )"

if [[ ${CATEGORY} != cross-* ]] ; then
	PDEPEND="${PDEPEND} elibc_glibc? ( >=sys-libs/glibc-2.12 )"
fi

src_unpack() {
	if has_version '<sys-libs/glibc-2.12' ; then
		ewarn "Your host glibc is too old"
		die 
	fi
	ewarn "This gcc version is for testing so NO BUGS REPORTS!"
	toolchain_src_unpack

	use vanilla && return 0

	[[ ${CHOST} == ${CTARGET} ]] && epatch "${FILESDIR}"/gcc-spec-env.patch
}

pkg_setup() {
	toolchain_pkg_setup

	ewarn
	ewarn "LTO support is still experimental and unstable."
	ewarn "Any bugs resulting from the use of LTO will not be fixed."
	ewarn
}
