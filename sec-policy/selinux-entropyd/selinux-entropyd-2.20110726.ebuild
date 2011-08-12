# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI="4"

IUSE=""
MODS="entropyd"

inherit selinux-policy-2

DESCRIPTION="SELinux policy for various entropy daemons (audio-entropyd, haveged, ...)"

KEYWORDS="~amd64 ~x86"
RDEPEND="!<sec-policy/selinux-audio-entropyd-2.20110726
		>=sys-apps/policycoreutils-1.30.30
		>=sec-policy/selinux-base-policy-${PV}"

pkg_postinst() {
	einfo "The SELinux entropyd module is the replacement of audioentropyd and"
	einfo "is made more generic for all-purpose entropy daemons, including"
	einfo "audioentropyd and haveged."
	einfo
	einfo "If you are upgrading from an audioentropyd module, the installation"
	einfo "of the new policy module might fail due to collisions. You will need"
	einfo "to remove the current audioentropyd module first:"
	einfo "  # semodule -r audioentropy"
	einfo
	einfo "Then, you can install the new policy:"
	einfo "  # semodule -i /usr/share/selinux/<type>/entropyd.pp"
	echo
	einfo "Portage will automatically try to load the entropyd module now."
	selinux-policy-2_pkg_postinst
}
