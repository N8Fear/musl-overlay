# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/profiles/default/linux/amd64/10.0/server/profile.bashrc,v 1.2 2010/11/14 11:03:00 hwoarang Exp $

if [[ "${EBUILD_PHASE}" == "setup" ]]
then
	if [[ ! "${I_KNOW_WHAT_I_AM_DOING}" == "yes" ]]
	then
		echo
		ewarn "This profile is merely a convenience for people who require a more"
		ewarn "minimal profile, yet are unable to use hardened due to restrictions in"
		ewarn "the software being used on the server. If you seek a secure"
		ewarn "production server profile, please check the Hardened project"
		ewarn "(http://hardened.gentoo.org)"
		echo
	fi
fi
