# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/policycoreutils/policycoreutils-2.0.69-r1.ebuild,v 1.2 2010/04/04 21:56:32 arfrever Exp $

IUSE="nls"

inherit eutils python

EXTRAS_VER="1.20"
SEMNG_VER="2.0.33"
SELNX_VER="2.0"

BUGFIX_PATCH="${FILESDIR}/policycoreutils-2.0.69-setfiles.diff"

DESCRIPTION="SELinux core utilities"
HOMEPAGE="http://userspace.selinuxproject.org"
SRC_URI="http://userspace.selinuxproject.org/releases/current/devel/${P}.tar.gz
	mirror://gentoo/policycoreutils-extra-${EXTRAS_VER}.tar.bz2"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"

COMMON_DEPS=">=sys-libs/libselinux-${SELNX_VER}
	>=sys-libs/glibc-2.4
	>=sys-process/audit-1.5.1
	>=sys-libs/libcap-1.10-r10
	sys-libs/pam
	>=sys-libs/libsemanage-${SEMNG_VER}"

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

	[ ! -z "${BUGFIX_PATCH}" ] && epatch "${BUGFIX_PATCH}"

	# rlpkg is more useful than fixfiles
	sed -i -e '/^all/s/fixfiles//' "${S}/scripts/Makefile" \
		|| die "fixfiles sed 1 failed"
	sed -i -e '/fixfiles/d' "${S}/scripts/Makefile" \
		|| die "fixfiles sed 2 failed"

	local SUBDIRS="`cd ${S} && find -type d | cut -d/ -f2`"

	if ! useq nls; then
		for i in ${SUBDIRS}; do
			# disable locale stuff
			sed -i -e s/-DUSE_NLS// "${S}/${i}/Makefile" \
				|| die "${i} NLS sed failed"
		done
	fi

	# Gentoo Fixes
	for i in ${SUBDIRS}; do
		# add in CFLAGS
		sed -i -e "s:-Wall:-Wall ${CFLAGS}:g" "${S}/${i}/Makefile" \
			|| die "${i} Makefile CFLAGS fix failed."
	done
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
