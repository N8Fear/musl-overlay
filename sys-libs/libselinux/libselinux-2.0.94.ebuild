# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-libs/libselinux/libselinux-2.0.85.ebuild,v 1.4 2010/09/29 22:58:55 vapier Exp $

EAPI="2"
IUSE="ruby"
RUBY_OPTIONAL="yes"

inherit eutils multilib python

SEPOL_VER="2.0.41"

DESCRIPTION="SELinux userland library"
HOMEPAGE="http://userspace.selinuxproject.org"
SRC_URI="http://userspace.selinuxproject.org/releases/20100525/devel/${P}.tar.gz"
LICENSE="public-domain"
SLOT="0"
KEYWORDS="~amd64 ~x86"

DEPEND=">=sys-libs/libsepol-${SEPOL_VER}
	dev-lang/swig
	ruby? ( dev-lang/ruby )"

RDEPEND=">=sys-libs/libsepol-${SEPOL_VER}
	ruby? ( dev-lang/ruby )"

src_unpack() {
	unpack ${A}
	cd "${S}"
}

src_prepare() {
	# fix up paths for multilib
	sed -i -e "/^LIBDIR/s/lib/$(get_libdir)/" "${S}/src/Makefile" \
		|| die "Fix for multilib LIBDIR failed."
	sed -i -e "/^SHLIBDIR/s/lib/$(get_libdir)/" "${S}/src/Makefile" \
		|| die "Fix for multilib SHLIBDIR failed."
}

src_compile() {
	emake LDFLAGS="-fPIC ${LDFLAGS}" all || die
	emake PYLIBVER="python$(python_get_version)" LDFLAGS="-fPIC ${LDFLAGS}" pywrap || die

	if use ruby; then
		emake rubywrap || die
	fi
}

src_install() {
	python_need_rebuild
	make DESTDIR="${D}" PYLIBVER="python$(python_get_version)" install install-pywrap || die

	if use ruby; then
		emake DESTDIR="${D}" install-rubywrap || die
	fi
}

pkg_postinst() {
	python_mod_optimize $(python_get_sitedir)
}

pkg_postrm() {
	python_mod_cleanup $(python_get_sitedir)
}
