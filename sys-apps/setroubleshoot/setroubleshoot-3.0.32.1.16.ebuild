# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=3

inherit versionator rpm eutils python

MY_PV="$(replace_version_separator 3 -)"
comp=($(get_all_version_components))
count=$(get_version_component_count)
last="$(( 2 * ${count} - 2 ))"
MY_PV="${MY_PV%${comp[$last]}}"
MY_PV="${MY_PV}fc${comp[$last]}"
S="${WORKDIR}/${PN}-${comp[0]}${comp[1]}${comp[2]}${comp[3]}${comp[4]}"

DESCRIPTION="Tool to analyse AVC Messages"
HOMEPAGE="https://fedorahosted.org/setroubleshoot"
SRC_URI="mirror://fedora/development/rawhide/source/SRPMS/${PN}-${MY_PV}.src.rpm"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="selinux"

DEPEND="dev-util/intltool"
RDEPEND="sys-apps/policycoreutils
	sys-libs/libselinux
	sys-apps/dbus
	x11-libs/gtk+
	x11-libs/libnotify
	www-client/htmlview"

src_unpack() {
	srcrpm_unpack
}

src_configure() {
	mv -f py-compile py-compile.ori \
		|| die "mv -f py-compile py-compile.orig failed."
	ln -s $(type -P true) py-compile \
		|| die "ln -s $(type -P true) py-compile failed."
	econf --prefix=/usr \
		--libdir=/usr/$(get_libdir) \
		--libexecdir=/usr/$(get_libdir) \
		--localstatedir=/var \
		|| die "Configure failure"
}

src_compile() {
	emake || die "Make failure"
}

src_install() {
	make DESTDIR="${D}" install \
		|| die "Install failure"

	rm -rf "${D}/usr/share/doc"
	dodoc AUTHORS ChangeLog README
	dodir /usr/share/setroubleshoot/plugins
}

pkg_postinst() {
	PYTHON
	python_need_rebuild
	python_mod_optimize /usr/share/setroubleshoot/plugins
}

pkg_postrm() {
	python_mod_cleanup /usr/share/setroubleshoot/plugins
}
