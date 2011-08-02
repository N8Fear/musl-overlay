# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-python/sepolgen/sepolgen-1.0.23.ebuild,v 1.3 2011/05/28 05:34:22 blueness Exp $

EAPI="2"
PYTHON_DEPEND="2:2.5"
SUPPORT_PYTHON_ABIS="1"
RESTRICT_PYTHON_ABIS="2.4 3.* *-jython"

inherit python

DESCRIPTION="SELinux policy generation library"
HOMEPAGE="http://userspace.selinuxproject.org"
SRC_URI="http://userspace.selinuxproject.org/releases/20110727/devel/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND=">=sys-libs/libselinux-2.0[python]"
RDEPEND="${DEPEND}"

src_prepare() {
	# fix up default paths to not be RH specific
	sed -i -e 's:/usr/share/selinux/devel:/usr/share/selinux/strict:' \
		"${S}/src/sepolgen/defaults.py" || die
	sed -i -e 's:/usr/share/selinux/devel:/usr/share/selinux/strict/include:' \
		"${S}/src/sepolgen/module.py" || die
}

src_compile() {
	:
}

src_test() {
	if has_version sec-policy/selinux-base-policy; then
		python_src_test
	else
		ewarn "Sepolgen requires sec-policy/selinux-base-policy to run tests."
	fi
}

src_install() {
	installation() {
		emake DESTDIR="${D}" PYTHONLIBDIR="$(python_get_sitedir)" install
	}
	python_execute_function installation
}

pkg_postinst() {
	python_mod_optimize sepolgen
}

pkg_postrm() {
	python_mod_cleanup sepolgen
}
