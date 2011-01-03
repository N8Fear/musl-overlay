# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-libs/libsemanage/libsemanage-2.0.33-r1.ebuild,v 1.2 2010/04/16 19:36:39 arfrever Exp $

IUSE=""

inherit eutils multilib python toolchain-funcs

SEPOL_VER="2.0.41"
SELNX_VER="2.0.94"

DESCRIPTION="SELinux kernel and policy management library"
HOMEPAGE="http://userspace.selinuxproject.org"
SRC_URI="http://userspace.selinuxproject.org/releases/20100525/devel/${P}.tar.gz"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
DEPEND=">=sys-libs/libsepol-${SEPOL_VER}
	>=sys-libs/libselinux-${SELNX_VER}
	dev-libs/ustr"
RDEPEND="${DEPEND}"

# tests are not meant to be run outside of the
# full SELinux userland repo
RESTRICT="test"

src_unpack() {
	unpack ${A}
	cd "${S}"

	echo "# Set this to true to save the linked policy." >> "${S}/src/semanage.conf"
	echo "# This is normally only useful for analysis" >> "${S}/src/semanage.conf"
	echo "# or debugging of policy." >> "${S}/src/semanage.conf"
	echo "save-linked=false" >> "${S}/src/semanage.conf"
	echo >> "${S}/src/semanage.conf"
	echo "# Set this to 0 to disable assertion checking." >> "${S}/src/semanage.conf"
	echo "# This should speed up building the kernel policy" >> "${S}/src/semanage.conf"
	echo "# from policy modules, but may leave you open to" >> "${S}/src/semanage.conf"
	echo "# dangerous rules which assertion checking" >> "${S}/src/semanage.conf"
	echo "# would catch." >> "${S}/src/semanage.conf"
	echo "expand-check=1" >> "${S}/src/semanage.conf"
	echo >> "${S}/src/semanage.conf"
	echo "# Modules in the module store can be compressed" >> "${S}/src/semanage.conf"
	echo "# with bzip2.  Set this to the bzip2 blocksize" >> "${S}/src/semanage.conf"
	echo "# 1-9 when compressing.  The higher the number," >> "${S}/src/semanage.conf"
	echo "# the more memory is traded off for disk space." >> "${S}/src/semanage.conf"
	echo "# Set to 0 to disable bzip2 compression." >> "${S}/src/semanage.conf"
	echo "bzip-blocksize=0" >> "${S}/src/semanage.conf"
	echo >> "${S}/src/semanage.conf"
	echo "# Reduce memory usage for bzip2 compression and" >> "${S}/src/semanage.conf"
	echo "# decompression of modules in the module store." >> "${S}/src/semanage.conf"
	echo "bzip-small=true" >> "${S}/src/semanage.conf"
}

src_compile() {
	emake PYLIBVER="python$(python_get_version)" all || die
	emake PYLIBVER="python$(python_get_version)" pywrap || die
}

src_install() {
	python_need_rebuild
	make DESTDIR="${D}" PYLIBVER="python$(python_get_version)" \
		LIBDIR="${D}/usr/$(get_libdir)/" \
		SHLIBDIR="${D}/$(get_libdir)/" install install-pywrap
	dosym "../../$(get_libdir)/libsemanage.so.1" "/usr/$(get_libdir)/libsemanage.so"
}

pkg_postinst() {
	python_mod_optimize $(python_get_sitedir)
}

pkg_postrm() {
	python_mod_cleanup $(python_get_sitedir)
}
