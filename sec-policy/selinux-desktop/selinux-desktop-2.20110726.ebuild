# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI="4"

DEPEND=">=sec-policy/selinux-xserver-2.20110726
	>=sec-policy/selinux-xfs-2.20110726
	>=sec-policy/selinux-mplayer-2.20110726
	>=sec-policy/selinux-java-2.20110726
	>=sec-policy/selinux-mono-2.20110726
	>=sec-policy/selinux-wine-2.20110726"

RDEPEND="acpi? ( sec-policy/selinux-acpi )
	apm? ( sec-policy/selinux-acpi )
	avahi? ( sec-policy/selinux-avahi )
	bluetooth? ( sec-policy/selinux-bluez )
	crypt? ( sec-policy/selinux-gnupg )
	dbus? ( sec-policy/selinux-dbus )
	pcmcia? ( sec-policy/selinux-pcmcia )"

IUSE="acpi apm avahi bluetooth crypt dbus pcmcia"

DESCRIPTION="SELinux policy for Desktop related apps (deprecated)"
HOMEPAGE="http://hardened.gentoo.org/selinux"
KEYWORDS="~amd64 ~x86"
SLOT="0"
LICENSE="public-domain"
