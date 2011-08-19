# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sec-policy/selinux-base-policy/selinux-base-policy-2.20101213-r18.ebuild,v 1.1 2011/07/10 02:30:17 blueness Exp $

EAPI="4"
IUSE="+peer_perms +open_perms +ubac"

inherit eutils

DESCRIPTION="Gentoo base policy for SELinux"
HOMEPAGE="http://www.gentoo.org/proj/en/hardened/selinux/"
SRC_URI="http://oss.tresys.com/files/refpolicy/refpolicy-${PV}.tar.bz2
	http://dev.gentoo.org/~swift/patches/${PN}/patchbundle-${PF}.tar.bz2"
LICENSE="GPL-2"
SLOT="0"

KEYWORDS="~amd64 ~x86"

RDEPEND=">=sys-apps/policycoreutils-1.30.30
	>=sys-fs/udev-151"
DEPEND="${RDEPEND}
	sys-devel/m4
	>=sys-apps/checkpolicy-1.30.12"

S=${WORKDIR}/

src_prepare() {
	# Apply the gentoo patches to the policy. These patches are only necessary
	# for base policies, or for interface changes on modules.
	EPATCH_MULTI_MSG="Applying SELinux policy updates ... " \
	EPATCH_SUFFIX="patch" \
	EPATCH_SOURCE="${WORKDIR}" \
	EPATCH_FORCE="yes" \
	epatch

	cd "${S}/refpolicy"
	# Fix bug 257111 - Correct the initial sid for cron-started jobs in the
	# system_r role
	sed -i -e 's:system_crond_t:system_cronjob_t:g' \
		"${S}/refpolicy/config/appconfig-standard/default_contexts"
	sed -i -e 's|system_r:cronjob_t|system_r:system_cronjob_t|g' \
		"${S}/refpolicy/config/appconfig-mls/default_contexts"
	sed -i -e 's|system_r:cronjob_t|system_r:system_cronjob_t|g' \
		"${S}/refpolicy/config/appconfig-mcs/default_contexts"
}

src_configure() {
	[ -z "${POLICY_TYPES}" ] && local POLICY_TYPES="targeted strict mls mcs"

	# Update the SELinux refpolicy capabilities based on the users' USE flags.

	if ! use peer_perms; then
		sed -i -e '/network_peer_controls/d' \
			"${S}/refpolicy/policy/policy_capabilities"
	fi

	if ! use open_perms; then
		sed -i -e '/open_perms/d' \
			"${S}/refpolicy/policy/policy_capabilities"
	fi

	if ! use ubac; then
		sed -i -e '/^UBAC/s/y/n/' "${S}/refpolicy/build.conf" \
			|| die "Failed to disable User Based Access Control"
	fi

	echo "DISTRO = gentoo" >> "${S}/refpolicy/build.conf"

	# Setup the policies based on the types delivered by the end user.
	# These types can be "targeted", "strict", "mcs" and "mls".
	for i in ${POLICY_TYPES}; do
		cp -a "${S}/refpolicy" "${S}/${i}"

		cd "${S}/${i}";
		make conf || die "Make conf in ${i} failed"

		# Define what we see as "base" and what we want to remain modular.
		cp "${FILESDIR}/modules.conf" \
			"${S}/${i}/policy/modules.conf" \
			|| die "failed to set up modules.conf"
		# In case of "targeted", we add the "unconfined" to the base policy
		if [[ "${i}" == "targeted" ]];
		then
			echo "unconfined = base" >> "${S}/${i}/policy/modules.conf"
		fi

		sed -i -e '/^QUIET/s/n/y/' -e "/^NAME/s/refpolicy/$i/" \
			"${S}/${i}/build.conf" || die "build.conf setup failed."

		if [[ "${i}" == "mls" ]] || [[ "${i}" == "mcs" ]];
		then
			# MCS/MLS require additional settings
			sed -i -e "/^TYPE/s/standard/${i}/" "${S}/${i}/build.conf" \
				|| die "failed to set type to mls"
		fi

		if [ "${i}" == "targeted" ]; then
			sed -i -e '/root/d' -e 's/user_u/unconfined_u/' \
			"${S}/${i}/config/appconfig-standard/seusers" \
			|| die "targeted seusers setup failed."
		fi
	done
}

src_compile() {
	[ -z "${POLICY_TYPES}" ] && local POLICY_TYPES="targeted strict mls mcs"

	for i in ${POLICY_TYPES}; do
		cd "${S}/${i}"
		make base || die "${i} compile failed"
	done
}

src_install() {
	[ -z "${POLICY_TYPES}" ] && local POLICY_TYPES="targeted strict mls mcs"

	for i in ${POLICY_TYPES}; do
		cd "${S}/${i}"

		make DESTDIR="${D}" install \
			|| die "${i} install failed."

		make DESTDIR="${D}" install-headers \
			|| die "${i} headers install failed."

		echo "run_init_t" > "${D}/etc/selinux/${i}/contexts/run_init_type"

		echo "textrel_shlib_t" >> "${D}/etc/selinux/${i}/contexts/customizable_types"

		# libsemanage won't make this on its own
		keepdir "/etc/selinux/${i}/policy"
	done

	dodoc doc/Makefile.example doc/example.{te,fc,if}

	insinto /etc/selinux
	doins "${FILESDIR}/config"
}

pkg_preinst() {
	has_version "<${CATEGORY}/${PN}-2.20101213-r13"
	previous_less_than_r13=$?
}

pkg_postinst() {
	[ -z "${POLICY_TYPES}" ] && local POLICY_TYPES="targeted strict mls mcs"

	for i in ${POLICY_TYPES}; do
		einfo "Inserting base module into ${i} module store."

		cd "${ROOT}/usr/share/selinux/${i}"
		semodule -s "${i}" -b base.pp || die "Could not load in new base policy"
	done
	elog "Updates on policies might require you to relabel files. If you, after"
	elog "installing new SELinux policies, get 'permission denied' errors,"
	elog "relabelling your system using 'rlpkg -a -r' might resolve the issues."
}
