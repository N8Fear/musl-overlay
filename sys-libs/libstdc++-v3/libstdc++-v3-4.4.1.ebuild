# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-libs/libstdc++-v3/libstdc++-v3-4.1.1.ebuild,v 1.25 2009/10/04 02.30.00 Zorry Exp $

inherit eutils flag-o-matic libtool multilib toolchain-funcs

do_filter_flags() {
	declare setting

	# In general gcc does not like optimization, and add -O2 where
	replace-flags -O? -O2

	# Don't build gcc with SSP if gcc < 4.2
	if [[ gcc-version < 4.2 ]] ; then
	filter-flags -fstack-protector-all
	filter-flags -fno-stack-protector-all
	filter-flags -fstack-protector
	filter-flags -fno-stack-protector
	fi

	strip-unsupported-flags

	strip-flags

}

PATCH_VER="1.0"

DESCRIPTION="Compatibility package for running binaries linked against a pre gcc 3.4 libstdc++"
HOMEPAGE="http://gcc.gnu.org/libstdc++/"
SRC_URI="ftp://gcc.gnu.org/pub/gcc/releases/gcc-${PV}/gcc-${PV}.tar.bz2
	mirror://gentoo/gcc-${PV}-patches-${PATCH_VER}.tar.bz2"

LICENSE="GPL-2 LGPL-2.1"
SLOT="5"
KEYWORDS="~amd64 ~hppa ~mips ~ppc -ppc64 ~sparc ~x86 ~x86-fbsd"
IUSE="multilib nls"

S=${WORKDIR}/gcc-${PV}

src_unpack() {
	unpack ${A}
	cd "${S}"
	EPATCH_SUFFIX="patch" epatch "${WORKDIR}"/patch

	# bug 285956
	if [[ gcc-version > 4.2 ]] ; then
		epatch "$FILESDIR"/libstdc++-v3-Makefile.in.patch
	fi

	elibtoolize --portage --shallow
	./contrib/gcc_update --touch
	mkdir -p "${WORKDIR}"/build

	if use multilib ; then
		# ugh, this shit has to match the way we've hacked gcc else
		# the build falls apart #259215
		sed -i \
			-e 's:\(MULTILIB_OSDIRNAMES = \).*:\1../lib64 ../lib32:' \
			"${S}"/gcc/config/i386/t-linux64 \
			|| die "sed failed!"
	fi
}

src_compile() {
	cd "${WORKDIR}"/build
	do_filter_flags
	ECONF_SOURCE=${S}
	econf \
		--enable-shared \
		--with-system-zlib \
		--enable-languages=c++ \
		--enable-stage1-languages=all \
		--enable-threads=posix \
		--enable-long-long \
		--disable-checking \
		--enable-cstdio=stdio \
		--enable-__cxa_atexit \
		$(use_enable multilib) \
		$(use_enable nls) \
		$(use_with !nls included-gettext) \
		|| die

	touch "${S}"/gcc/c-gperf.h

	emake all-target-libstdc++-v3 || die
}

src_install() {
	emake -j1 \
		-C "${WORKDIR}"/build \
		DESTDIR="${D}" \
		install-target-libstdc++-v3 || die

	# scrub everything but the library we care about
	pushd "${D}" >/dev/null
	mv usr/lib* . || die
	rm -rf usr
	rm -f lib*/*.{a,la,so} || die
	dodir /usr
	mv lib* usr/ || die
}
