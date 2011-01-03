# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/policycoreutils/policycoreutils-2.0.69-r1.ebuild,v 1.2 2010/04/04 21:56:32 arfrever Exp $

IUSE="nls"

inherit eutils python

EXTRAS_VER="1.20"
SEMNG_VER="2.0.45"
SELNX_VER="2.0.94"
SEPOL_VER="2.0.41"

#BUGFIX_PATCH="${FILESDIR}/policycoreutils-2.0.62-po.diff"

DESCRIPTION="SELinux core utilities"
HOMEPAGE="http://userspace.selinuxproject.org"
SRC_URI="http://userspace.selinuxproject.org/releases/20100525/devel/${P}.tar.gz
	mirror://gentoo/policycoreutils-extra-${EXTRAS_VER}.tar.bz2"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"

COMMON_DEPS=">=sys-libs/libselinux-${SELNX_VER}
	>=sys-libs/glibc-2.4
	>=sys-process/audit-1.5.1
	>=sys-libs/libcap-1.10-r10
	sys-libs/pam
	>=sys-libs/libsemanage-${SEMNG_VER}
	sys-libs/libcap-ng
	>=sys-libs/libsepol-${SEPOL_VER}"

# pax-utils for scanelf used by rlpkg
RDEPEND="${COMMON_DEPS}
	dev-python/sepolgen
	app-misc/pax-utils"

DEPEND="${COMMON_DEPS}
	nls? ( sys-devel/gettext )"

S2=${WORKDIR}/policycoreutils-extra

src_unpack() {
	unpack ${A}
	cd "${S}"

	# rlpkg is more useful than fixfiles
	sed -i -e '/^all/s/fixfiles//' "${S}/scripts/Makefile" \
		|| die "fixfiles sed 1 failed"
	sed -i -e '/fixfiles/d' "${S}/scripts/Makefile" \
		|| die "fixfiles sed 2 failed"
	# removing sandbox for the time being, need to
	# rename in future to sesandbox?
	sed -i -e 's/sandbox //' "${S}/Makefile" \
		|| die "failed removing sandbox"
}

src_compile() {
	einfo "Compiling policycoreutils"
	emake -C "${S}" PYLIBVER="python$(python_get_version)" AUDIT_LOG_PRIV=y || die
	einfo "Compiling policycoreutils-extra"
	emake -C "${S2}" || die
}

src_install() {
	python_need_rebuild

	einfo "Installing policycoreutils"
	make DESTDIR="${D}" -C "${S}" PYLIBVER="python$(python_get_version)" AUDIT_LOG_PRIV=y install || die
	einfo "Installing policycoreutils-extra"
	make DESTDIR="${D}" -C "${S2}" install || die

	# remove redhat-style init script
	rm -fR "${D}/etc/rc.d"

	# compatibility symlinks
	dosym /sbin/setfiles /usr/sbin/setfiles
	dosym /lib/rc/runscript_selinux.so /lib/rcscripts/runscript_selinux.so

	if has_version '<sys-libs/pam-0.99'; then
		# install compat pam.d entries
		# for older pam
		make DESTDIR="${D}" -C "${S2}/pam.d" install || die
	fi
}

pkg_postinst() {
	python_mod_optimize $(python_get_sitedir)
}

pkg_postrm() {
	python_mod_cleanup $(python_get_sitedir)
}
