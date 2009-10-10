# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-kernel/hardened-sources/hardened-sources-2.6.29.ebuild,v 1.1 2009/05/25 04:36:12 gengor Exp $

ETYPE="sources"
K_WANT_GENPATCHES="base extras"
K_GENPATCHES_VER="3"

inherit kernel-2
detect_version

HGPV="${KV_MAJOR}.${KV_MINOR}.${KV_PATCH}-5"
HGPV_URI="http://dev.gentoo.org/~anarchy/dist/hardened-patches-${HGPV}.extras.tar.bz2"
SRC_URI="${KERNEL_URI} ${HGPV_URI} ${GENPATCHES_URI} ${ARCH_URI}"

UNIPATCH_LIST="${DISTDIR}/hardened-patches-${HGPV}.extras.tar.bz2"
UNIPATCH_EXCLUDE="4201_fbcondecor-0.9.6.patch"

DESCRIPTION="Hardened kernel sources (kernel series ${KV_MAJOR}.${KV_MINOR})"
HOMEPAGE="http://www.gentoo.org/proj/en/hardened/"
IUSE=""

KEYWORDS="~alpha ~amd64 ~hppa ~ia64 ~ppc ~ppc64 ~sparc ~x86"

pkg_postinst() {
	kernel-2_pkg_postinst

	local GRADM_COMPAT="sys-apps/gradm-2.1.14*"

	ewarn
	ewarn "As of ${CATEGORY}/${PN}-2.6.24 the predefined"
	ewarn "\"Hardened [Gentoo]\" grsecurity level has been removed."
	ewarn "Two improved predefined security levels replace it:"
	ewarn "\"Hardened Gentoo [server]\" and \"Hardened Gentoo [workstation]\""
	ewarn
	ewarn "Those who intend to use one of these predefined grsecurity levels"
	ewarn "should read the help associated with the level. Users importing a"
	ewarn "kernel configuration from a kernel prior to ${PN}-2.6.24,"
	ewarn "should review their selected grsecurity/PaX options carefully."
	ewarn
	ewarn
	ewarn "Users of grsecurity's RBAC system must ensure they are using"
	ewarn "${GRADM_COMPAT}, which is compatible with kernel series ${OKV}."
	ewarn "Therefore, it is strongly recommended that the following command is"
	ewarn "issued prior to booting a ${P} series kernel for"
	ewarn "the first time:"
	ewarn
	ewarn "emerge -na =${GRADM_COMPAT}"
	ewarn
}
