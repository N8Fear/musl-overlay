# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/selinux-policy-2.eclass,v 1.6 2011/05/20 19:06:07 blueness Exp $

# Eclass for installing SELinux policy, and optionally
# reloading the reference-policy based modules.

# @ECLASS: selinux-policy-2.eclass
# @MAINTAINER: 
# selinux@gentoo.org
# @BLURB: This eclass supports the deployment of the various SELinux modules in sec-policy
# @DESCRIPTION:
# The selinux-policy-2.eclass supports deployment of the various SELinux modules
# defined in the sec-policy category. It is responsible for extracting the
# specific bits necessary for single-module deployment (instead of full-blown
# policy rebuilds) and applying the necessary patches.
# 
# Also, it supports for bundling patches to make the whole thing just a bit more
# manageable.

# @ECLASS-VARIABLE: MODS
# @DESCRIPTION: 
# This variable contains the (upstream) module name for the SELinux module.
# This name is only the module name, not the category!
: ${MODS:="_illegal"}

# @ECLASS-VARIABLE: BASEPOL
# @DESCRIPTION:
# This variable contains the version string of the selinux-base-policy package
# that this module build depends on. It is used to patch with the appropriate
# patch bundle(s) that are part of selinux-base-policy. 
: ${BASEPOL:=""}

# @ECLASS-VARIABLE: POLICY_PATCH
# @DESCRIPTION:
# This variable contains the additional patch(es) that need to be applied on top
# of the patchset already contained within the BASEPOL variable. 
: ${POLICY_PATCH:=""}

# @ECLASS-VARIABLE: POLICY_TYPES
# @DESCRIPTION:
# This variable informs the eclass for which SELinux policies the module should
# be built. Currently, Gentoo supports targeted, strict, mcs and mls.
# This variable is the same POLICY_TYPES variable that we tell SELinux
# users to set in /etc/make.conf. Therefor, it is not the module that should
# override it, but the user.
: ${POLICY_TYPES:="targeted strict mcs mls"}

inherit eutils

IUSE=""

HOMEPAGE="http://www.gentoo.org/proj/en/hardened/selinux/"
if [[ -n ${BASEPOL} ]];
then
	SRC_URI="http://oss.tresys.com/files/refpolicy/refpolicy-${PV}.tar.bz2"
else
	SRC_URI="http://oss.tresys.com/files/refpolicy/refpolicy-${PV}.tar.bz2
		http://dev.gentoo.org/~blueness/patchbundle-selinux-base-policy/patchbundle-selinux-base-policy-${BASEPOL}.tar.bz2"
fi

LICENSE="GPL-2"
SLOT="0"
S="${WORKDIR}/"
PATCHBUNDLE="${DISTDIR}/patchbundle-selinux-base-policy-${BASEPOL}.tar.bz2"

# Modules should always depend on at least the first release of the
# selinux-base-policy for which they are generated.
if [[ -n ${BASEPOL} ]];
then
	RDEPEND=">=sys-apps/policycoreutils-2.0.82
		>=sec-policy/selinux-base-policy-${PV}"
else
	RDEPEND=">=sys-apps/policycoreutils-2.0.82
		>=sec-policy/selinux-base-policy-${BASEPOL}"
fi
DEPEND="${RDEPEND}
	sys-devel/m4
	>=sys-apps/checkpolicy-2.0.21"

SELINUX_EXPF="src_unpack src_compile src_install pkg_postinst"
case "${EAPI:-0}" in
	2|3|4) SELINUX_EXPF+=" src_prepare" ;;
	*) ;;
esac

EXPORT_FUNCTIONS ${SELINUX_EXPF}

# @FUNCTION: selinux-policy-2_src_unpack
# @DESCRIPTION:
# Unpack the policy sources as offered by upstream (refpolicy). In case of EAPI
# older than 2, call src_prepare too.
selinux-policy-2_src_unpack() {
	unpack ${A}

	# Call src_prepare explicitly for EAPI 0 or 1
	has "${EAPI:-0}" 0 1 && selinux-policy-2_src_prepare
}

# @FUNCTION: selinux-policy-2_src_prepare
# @DESCRIPTION:
# Patch the reference policy sources with our set of enhancements. Start with
# the base patchbundle referred to by the ebuilds through the BASEPOL variable,
# then apply the additional patches as offered by the ebuild.
# 
# Next, extract only those files needed for this particular module (i.e. the .te
# and .fc files for the given module in the MODS variable).
# 
# Finally, prepare the build environments for each of the supported SELinux
# types (such as targeted or strict), depending on the POLICY_TYPES variable
# content.
selinux-policy-2_src_prepare() {
	local modfiles

	# Patch the sources with the base patchbundle
	if [[ -n ${BASEPOL} ]];
	then
		cd "${S}"
		epatch "${PATCHBUNDLE}"
	fi

	# Apply the additional patches refered to by the module ebuild
	if [[ -n "${POLICY_PATCH}" ]];
	then
		for POLPATCH in "${POLICY_PATCH}";
		do
			cd "${S}/refpolicy/policy/modules"
			epatch "${POLPATCH}"
		done
	fi

	# Collect only those files needed for this particular module
	for i in ${MODS}; do
		modfiles="$(find ${S}/refpolicy/policy/modules -iname $i.te) $modfiles"
		modfiles="$(find ${S}/refpolicy/policy/modules -iname $i.fc) $modfiles"
	done

	for i in ${POLICY_TYPES}; do
		mkdir "${S}"/${i} || die "Failed to create directory ${S}/${i}"
		cp "${S}"/refpolicy/doc/Makefile.example "${S}"/${i}/Makefile \
			|| die "Failed to copy Makefile.example to ${S}/${i}/Makefile"

		cp ${modfiles} "${S}"/${i} \
			|| die "Failed to copy the module files to ${S}/${i}"
	done
}

# @FUNCTION: selinux-policy-2_src_compile
# @DESCRIPTION: 
# Build the SELinux policy module (.pp file) for just the selected module, and
# this for each SELinux policy mentioned in POLICY_TYPES
selinux-policy-2_src_compile() {
	for i in ${POLICY_TYPES}; do
		emake NAME=$i -C "${S}"/${i} || die "${i} compile failed"
	done
}

# @FUNCTION: selinux-policy-2_src_install
# @DESCRIPTION:
# Install the built .pp files in the correct subdirectory within
# /usr/share/selinux.
selinux-policy-2_src_install() {
	local BASEDIR="/usr/share/selinux"

	for i in ${POLICY_TYPES}; do
		for j in ${MODS}; do
			einfo "Installing ${i} ${j} policy package"
			insinto ${BASEDIR}/${i}
			doins "${S}"/${i}/${j}.pp || die "Failed to add ${j}.pp to ${i}"
		done
	done
}

# @FUNCTION: selinux-policy-2_pkg_postinst
# @DESCRIPTION:
# Install the built .pp files in the SELinux policy stores, effectively
# activating the policy on the system.
selinux-policy-2_pkg_postinst() {
	# build up the command in the case of multiple modules
	local COMMAND
	for i in ${MODS}; do
		COMMAND="-i ${i}.pp ${COMMAND}"
	done

	for i in ${POLICY_TYPES}; do
		einfo "Inserting the following modules into the $i module store: ${MODS}"

		cd /usr/share/selinux/${i} || die "Could not enter /usr/share/selinux/${i}"
		semodule -s ${i} ${COMMAND} || die "Failed to load in modules ${MODS} in the $i policy store"
	done
}

