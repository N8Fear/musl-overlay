# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-libs/libsemanage/libsemanage-2.0.46.ebuild,v 1.1 2011/07/15 21:00:46 blueness Exp $

EAPI="3"
# Support for 4 depends on python.eclass
PYTHON_DEPEND="python? *"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="*-jython"

inherit multilib python toolchain-funcs

SEPOL_VER="2.1.0"
SELNX_VER="2.1.0"

DESCRIPTION="SELinux kernel and policy management library"
HOMEPAGE="http://userspace.selinuxproject.org"
SRC_URI="http://userspace.selinuxproject.org/releases/20110727/devel/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="python ruby"

RDEPEND=">=sys-libs/libsepol-${SEPOL_VER}
	>=sys-libs/libselinux-${SELNX_VER}
	dev-libs/ustr
	ruby? ( dev-lang/ruby )"
DEPEND="${RDEPEND}
	ruby? ( dev-lang/swig )"

# tests are not meant to be run outside of the
# full SELinux userland repo
RESTRICT="test"

pkg_setup() {
	if use python; then
		python_pkg_setup
	fi
}

src_prepare() {
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
	emake AR="$(tc-getAR)" CC="$(tc-getCC)" all || die

	if use python; then
		python_copy_sources src
		building() {
			emake CC="$(tc-getCC)" PYLIBVER="python$(python_get_version)" "$@"
		}
		python_execute_function -s --source-dir src building -- swigify
		python_execute_function -s --source-dir src building -- pywrap
	fi

	if use ruby; then
		emake -C src CC="$(tc-getCC)" rubywrap || die
	fi
}

src_install() {
	emake \
		DESTDIR="${D}" \
		LIBDIR="${D}usr/$(get_libdir)" \
		SHLIBDIR="${D}$(get_libdir)" \
		install || die
	dosym "../../$(get_libdir)/libsemanage.so.1" "/usr/$(get_libdir)/libsemanage.so" || die

	if use python; then
		installation() {
			emake \
				DESTDIR="${D}" \
				PYLIBVER="python$(python_get_version)" \
				LIBDIR="${D}usr/$(get_libdir)" \
				install-pywrap
		}
		python_execute_function -s --source-dir src installation
	fi

	if use ruby; then
		emake -C src \
			DESTDIR="${D}" \
			LIBDIR="${D}usr/$(get_libdir)" \
			install-rubywrap || die
	fi
}

pkg_postinst() {
	if use python; then
		python_mod_optimize semanage.py
	fi
}

pkg_postrm() {
	if use python; then
		python_mod_cleanup semanage.py
	fi
}
