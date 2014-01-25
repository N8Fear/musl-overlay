# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/gcc/gcc-4.7.3.ebuild,v 1.2 2013/05/20 10:56:06 aballier Exp $

EAPI=4

PATCH_VER="1.0"
UCLIBC_VER="1.0"

# Hardened gcc 4 stuff
PIE_VER="0.5.5"
SPECS_VER="0.2.0"
SPECS_GCC_VER="4.4.3"
# arch/libc configurations known to be stable with {PIE,SSP}-by-default
PIE_GLIBC_STABLE="x86 amd64 ppc ppc64 arm ia64"
PIE_UCLIBC_STABLE="x86 arm amd64 ppc ppc64"
SSP_STABLE="amd64 x86 ppc ppc64 arm"
# uclibc need tls and nptl support for SSP support
# uclibc need to be >= 0.9.33
SSP_UCLIBC_STABLE="x86 amd64 ppc ppc64 arm"
#end Hardened stuff

inherit toolchain eutils

DESCRIPTION="The GNU Compiler Collection"

LICENSE="GPL-3+ LGPL-3+ || ( GPL-3+ libgcc libstdc++ gcc-runtime-library-exception-3.1 ) FDL-1.3+"

KEYWORDS="~alpha amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 -amd64-fbsd -x86-fbsd"

RDEPEND=""
DEPEND="${RDEPEND}
	>=${CATEGORY}/binutils-2.18"

src_unpack() {
	toolchain_src_unpack

	if use elibc_musl; then
		cd "${S}"
		sed -i 's@\./fixinc\.sh@-c true@' gcc/Makefile.in
		mv libstdc\+\+-v3/config/os/gnu-linux libstdc\+\+-v3/config/os/gnu-linux.org
		cp -r libstdc\+\+-v3/config/os/generic libstdc\+\+-v3/config/os/gnu-linux
		cp libstdc++-v3/config/os/gnu-linux.org/arm-eabi-extra.ver libstdc++-v3/config/os/gnu-linux/
		mv libitm/config/linux/x86 libitm/config/linux/x86_glibc
		cp -r libitm/config/generic libitm/config/linux/x86

		epatch "${FILESDIR}"/${P}-musl-linker-path.patch
	fi

	use vanilla && return 0

	[[ ${CHOST} == ${CTARGET} ]] && epatch "${FILESDIR}"/gcc-spec-env.patch
}

src_install() {
	toolchain_src_install

	# Because /usr/lib/gcc/.. is not in musl search path
	# cp-ing libgcc_s.so.1 is the safest way but it does
	# mess up gcc-config which will need patching for this.
	cp "${D}"/usr/lib/gcc/${CHOST}/${PV}/libgcc_s.so.1 "${D}"/usr/lib
}

pkg_setup() {
	toolchain_pkg_setup
}
