# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sec-policy/selinux-acpi/selinux-acpi-2.20091215.ebuild,v 1.1 2009/12/16 02:53:59 pebenito Exp $

IUSE=""

MODS="networkmanager"

inherit selinux-policy-2

DESCRIPTION="SELinux policy for general applications"

KEYWORDS="~amd64 ~x86"

MODDEPEND=">=sec-policy/selinux-base-policy-2.20101213-r1"

# Patch "fix-networkmanager.patch" contains:
# - Support for wpa_cli. Gentoo's init scripts use wpa_cli to run the init
#   scripts when wpa_supplicant has associated.
# - Support running wpa_cli from commandline (requires
#   selinux-base-policy-2.20101213-r1) due to patch to sysadm_t domain
POLICY_PATCH="${FILESDIR}/fix-networkmanager.patch"
