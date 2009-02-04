# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/toolchain.eclass,v 1.368 2008/12/22 18:53:47 solar Exp $
#
# Maintainer: Toolchain Ninjas <toolchain@gentoo.org>

HOMEPAGE="http://gcc.gnu.org/"
LICENSE="GPL-2 LGPL-2.1"
RESTRICT="strip" # cross-compilers need controlled stripping

#---->> eclass stuff <<----
inherit eutils versionator libtool toolchain-funcs flag-o-matic gnuconfig multilib fixheadtails hardened-funcs
___ECLASS_RECUR_TOOLCHAIN="yes"

EXPORT_FUNCTIONS pkg_setup src_unpack src_compile src_test pkg_preinst src_install pkg_postinst pkg_prerm pkg_postrm
DESCRIPTION="Based on the ${ECLASS} eclass"

FEATURES=${FEATURES/multilib-strict/}

toolchain_pkg_setup() {
	gcc_pkg_setup
}
toolchain_src_unpack() {
	gcc_src_unpack
}
toolchain_src_compile() {
	gcc_src_compile
}
toolchain_src_test() {
	gcc_src_test
}
toolchain_pkg_preinst() {
	${ETYPE}_pkg_preinst
}
toolchain_src_install() {
	${ETYPE}_src_install
}
toolchain_pkg_postinst() {
	${ETYPE}_pkg_postinst
}
toolchain_pkg_prerm() {
	${ETYPE}_pkg_prerm
}
toolchain_pkg_postrm() {
	${ETYPE}_pkg_postrm
}
#----<< eclass stuff >>----


#---->> globals <<----
export CTARGET=${CTARGET:-${CHOST}}
if [[ ${CTARGET} = ${CHOST} ]] ; then
	if [[ ${CATEGORY/cross-} != ${CATEGORY} ]] ; then
		export CTARGET=${CATEGORY/cross-}
	fi
fi
is_crosscompile() {
	[[ ${CHOST} != ${CTARGET} ]]
}

tc_version_is_at_least() { version_is_at_least "$1" "${2:-${GCC_PV}}" ; }


GCC_PV=${TOOLCHAIN_GCC_PV:-${PV}}
GCC_PVR=${GCC_PV}
[[ ${PR} != "r0" ]] && GCC_PVR=${GCC_PVR}-${PR}
GCC_RELEASE_VER=$(get_version_component_range 1-3 ${GCC_PV})
GCC_BRANCH_VER=$(get_version_component_range 1-2 ${GCC_PV})
GCCMAJOR=$(get_version_component_range 1 ${GCC_PV})
GCCMINOR=$(get_version_component_range 2 ${GCC_PV})
GCCMICRO=$(get_version_component_range 3 ${GCC_PV})
[[ ${BRANCH_UPDATE-notset} == "notset" ]] && BRANCH_UPDATE=$(get_version_component_range 4 ${GCC_PV})

# According to gcc/c-cppbuiltin.c, GCC_CONFIG_VER MUST match this regex.
# ([^0-9]*-)?[0-9]+[.][0-9]+([.][0-9]+)?([- ].*)?
GCC_CONFIG_VER=${GCC_CONFIG_VER:-$(replace_version_separator 3 '-' ${GCC_PV})}

# Pre-release support
if [[ ${GCC_PV} != ${GCC_PV/_pre/-} ]] ; then
	PRERELEASE=${GCC_PV/_pre/-}
fi
# make _alpha and _beta ebuilds automatically use a snapshot
if [[ ${GCC_PV} != ${GCC_PV/_alpha/} ]] ; then
	SNAPSHOT=${GCC_BRANCH_VER}-${GCC_PV##*_alpha}
elif [[ ${GCC_PV} != ${GCC_PV/_beta/} ]] ; then
	SNAPSHOT=${GCC_BRANCH_VER}-${GCC_PV##*_beta}
fi
export GCC_FILESDIR=${GCC_FILESDIR:-${FILESDIR}}

if [[ ${ETYPE} == "gcc-library" ]] ; then
	GCC_VAR_TYPE=${GCC_VAR_TYPE:-non-versioned}
	GCC_LIB_COMPAT_ONLY=${GCC_LIB_COMPAT_ONLY:-true}
	GCC_TARGET_NO_MULTILIB=${GCC_TARGET_NO_MULTILIB:-true}
else
	GCC_VAR_TYPE=${GCC_VAR_TYPE:-versioned}
	GCC_LIB_COMPAT_ONLY="false"
	GCC_TARGET_NO_MULTILIB=${GCC_TARGET_NO_MULTILIB:-false}
fi

PREFIX=${TOOLCHAIN_PREFIX:-/usr}

if [[ ${GCC_VAR_TYPE} == "versioned" ]] ; then
	if tc_version_is_at_least 3.4.0 ; then
		LIBPATH=${TOOLCHAIN_LIBPATH:-${PREFIX}/lib/gcc/${CTARGET}/${GCC_CONFIG_VER}}
	else
		LIBPATH=${TOOLCHAIN_LIBPATH:-${PREFIX}/lib/gcc-lib/${CTARGET}/${GCC_CONFIG_VER}}
	fi
	INCLUDEPATH=${TOOLCHAIN_INCLUDEPATH:-${LIBPATH}/include}
	if is_crosscompile ; then
		BINPATH=${TOOLCHAIN_BINPATH:-${PREFIX}/${CHOST}/${CTARGET}/gcc-bin/${GCC_CONFIG_VER}}
	else
		BINPATH=${TOOLCHAIN_BINPATH:-${PREFIX}/${CTARGET}/gcc-bin/${GCC_CONFIG_VER}}
	fi
	DATAPATH=${TOOLCHAIN_DATAPATH:-${PREFIX}/share/gcc-data/${CTARGET}/${GCC_CONFIG_VER}}
	# Dont install in /usr/include/g++-v3/, but in gcc internal directory.
	# We will handle /usr/include/g++-v3/ with gcc-config ...
	STDCXX_INCDIR=${TOOLCHAIN_STDCXX_INCDIR:-${LIBPATH}/include/g++-v${GCC_BRANCH_VER/\.*/}}
elif [[ ${GCC_VAR_TYPE} == "non-versioned" ]] ; then
	# using non-versioned directories to install gcc, like what is currently
	# done for ppc64 and 3.3.3_pre, is a BAD IDEA. DO NOT do it!! However...
	# setting up variables for non-versioned directories might be useful for
	# specific gcc targets, like libffi. Note that we dont override the value
	# returned by get_libdir here.
	LIBPATH=${TOOLCHAIN_LIBPATH:-${PREFIX}/$(get_libdir)}
	INCLUDEPATH=${TOOLCHAIN_INCLUDEPATH:-${PREFIX}/include}
	BINPATH=${TOOLCHAIN_BINPATH:-${PREFIX}/bin}
	DATAPATH=${TOOLCHAIN_DATAPATH:-${PREFIX}/share}
	STDCXX_INCDIR=${TOOLCHAIN_STDCXX_INCDIR:-${PREFIX}/include/g++-v3}
fi

#----<< globals >>----


#---->> SLOT+IUSE logic <<----
if [[ ${ETYPE} == "gcc-library" ]] ; then
	IUSE="nls build test"
	SLOT="${CTARGET}-${SO_VERSION_SLOT:-5}"
else
	IUSE="multislot test"

	if [[ ${PN} != "kgcc64" && ${PN} != gcc-* ]] ; then
		IUSE="${IUSE} altivec build fortran nls nocxx"
		[[ -n ${PIE_VER} ]] && IUSE="${IUSE} nopie"
		[[ -n ${PP_VER}	 ]] || [[ -n ${SPECS_VER} ]] && IUSE="${IUSE} nossp"
		[[ -n ${HTB_VER} ]] && IUSE="${IUSE} boundschecking"
		[[ -n ${D_VER}	 ]] && IUSE="${IUSE} d"

		if tc_version_is_at_least 3 ; then
			IUSE="${IUSE} bootstrap doc gcj gtk hardened libffi multilib objc vanilla"

			# gcc-{nios2,bfin} don't accept these
			if [[ ${PN} == "gcc" ]] ; then
				IUSE="${IUSE} ip28 ip32r10k n32 n64"
			fi

			tc_version_is_at_least "4.0" && IUSE="${IUSE} objc-gc mudflap"
			tc_version_is_at_least "4.1" && IUSE="${IUSE} objc++"
			tc_version_is_at_least "4.2" && IUSE="${IUSE} openmp"
			tc_version_is_at_least "4.3" && IUSE="${IUSE} fixed-point"
		fi
	fi

	# Support upgrade paths here or people get pissed
	if use multislot ; then
		SLOT="${CTARGET}-${GCC_CONFIG_VER}"
	elif is_crosscompile; then
		SLOT="${CTARGET}-${GCC_BRANCH_VER}"
	else
		SLOT="${GCC_BRANCH_VER}"
	fi
fi
#----<< SLOT+IUSE logic >>----


#---->> S + SRC_URI essentials <<----

# This function sets the source directory depending on whether we're using
# a prerelease, snapshot, or release tarball. To use it, just set S with:
#
#	S="$(gcc_get_s_dir)"
#
# Travis Tilley <lv@gentoo.org> (03 Sep 2004)
#
gcc_get_s_dir() {
	local GCC_S
	if [[ -n ${PRERELEASE} ]] ; then
		GCC_S=${WORKDIR}/gcc-${PRERELEASE}
	elif [[ -n ${SNAPSHOT} ]] ; then
		GCC_S=${WORKDIR}/gcc-${SNAPSHOT}
	else
		GCC_S=${WORKDIR}/gcc-${GCC_RELEASE_VER}
	fi
	echo "${GCC_S}"
}

# This function handles the basics of setting the SRC_URI for a gcc ebuild.
# To use, set SRC_URI with:
#
#	SRC_URI="$(get_gcc_src_uri)"
#
# Other than the variables normally set by portage, this function's behavior
# can be altered by setting the following:
#
#	SNAPSHOT
#			If set, this variable signals that we should be using a snapshot
#			of gcc from ftp://sources.redhat.com/pub/gcc/snapshots/. It is
#			expected to be in the format "YYYY-MM-DD". Note that if the ebuild
#			has a _pre suffix, this variable is ignored and the prerelease
#			tarball is used instead.
#
#	BRANCH_UPDATE
#			If set, this variable signals that we should be using the main
#			release tarball (determined by ebuild version) and applying a
#			CVS branch update patch against it. The location of this branch
#			update patch is assumed to be in ${GENTOO_TOOLCHAIN_BASE_URI}.
#			Just like with SNAPSHOT, this variable is ignored if the ebuild
#			has a _pre suffix.
#
#	PATCH_VER
#	PATCH_GCC_VER
#			This should be set to the version of the gentoo patch tarball.
#			The resulting filename of this tarball will be:
#			gcc-${PATCH_GCC_VER:-${GCC_RELEASE_VER}}-patches-${PATCH_VER}.tar.bz2
#
#	HTB_VER
#	HTB_GCC_VER
#			These variables control whether or not an ebuild supports Herman
#			ten Brugge's bounds-checking patches. If you want to use a patch
#			for an older gcc version with a new gcc, make sure you set
#			HTB_GCC_VER to that version of gcc.
#
#	MAN_VER
#			The version of gcc for which we will download manpages. This will
#			default to ${GCC_RELEASE_VER}, but we may not want to pre-generate man pages
#			for prerelease test ebuilds for example. This allows you to
#			continue using pre-generated manpages from the last stable release.
#			If set to "none", this will prevent the downloading of manpages,
#			which is useful for individual library targets.
#
gentoo_urls() {
	local devspace="HTTP~lv/GCC/URI HTTP~eradicator/gcc/URI HTTP~vapier/dist/URI
	HTTP~halcy0n/patches/URI"
	devspace=${devspace//HTTP/http:\/\/dev.gentoo.org\/}
	echo mirror://gentoo/$1 ${devspace//URI/$1}
}
get_gcc_src_uri() {
	export PATCH_GCC_VER=${PATCH_GCC_VER:-${GCC_RELEASE_VER}}
	export UCLIBC_GCC_VER=${UCLIBC_GCC_VER:-${PATCH_GCC_VER}}
	export HTB_GCC_VER=${HTB_GCC_VER:-${GCC_RELEASE_VER}}
	
	# Set where to download gcc itself depending on whether we're using a
	# prerelease, snapshot, or release tarball.
	if [[ -n ${PRERELEASE} ]] ; then
		GCC_SRC_URI="ftp://gcc.gnu.org/pub/gcc/prerelease-${PRERELEASE}/gcc-${PRERELEASE}.tar.bz2"
	elif [[ -n ${SNAPSHOT} ]] ; then
		GCC_SRC_URI="ftp://sources.redhat.com/pub/gcc/snapshots/${SNAPSHOT}/gcc-${SNAPSHOT}.tar.bz2"
	else
		GCC_SRC_URI="mirror://gnu/gcc/gcc-${GCC_PV}/gcc-${GCC_RELEASE_VER}.tar.bz2"
		# we want all branch updates to be against the main release
		[[ -n ${BRANCH_UPDATE} ]] && \
			GCC_SRC_URI="${GCC_SRC_URI} $(gentoo_urls gcc-${GCC_RELEASE_VER}-branch-update-${BRANCH_UPDATE}.patch.bz2)"
	fi

	# uclibc lovin
	[[ -n ${UCLIBC_VER} ]] && \
		GCC_SRC_URI="${GCC_SRC_URI} $(gentoo_urls gcc-${UCLIBC_GCC_VER}-uclibc-patches-${UCLIBC_VER}.tar.bz2)"

	# PERL cannot be present at bootstrap, and is used to build the man pages.
	# So... lets include some pre-generated ones, shall we?
	[[ -n ${MAN_VER} ]] && \
		GCC_SRC_URI="${GCC_SRC_URI} $(gentoo_urls gcc-${MAN_VER}-manpages.tar.bz2)"

	# various gentoo patches
	[[ -n ${PATCH_VER} ]] && \
		GCC_SRC_URI="${GCC_SRC_URI} $(gentoo_urls gcc-${PATCH_GCC_VER}-patches-${PATCH_VER}.tar.bz2)"

	# gcc bounds checking patch
	if [[ -n ${HTB_VER} ]] ; then
		local HTBFILE="bounds-checking-gcc-${HTB_GCC_VER}-${HTB_VER}.patch.bz2"
		GCC_SRC_URI="${GCC_SRC_URI}
			boundschecking? (
				mirror://sourceforge/boundschecking/${HTBFILE}
				$(gentoo_urls ${HTBFILE})
			)"
	fi

	# support for the D language
	[[ -n ${D_VER} ]] && \
		GCC_SRC_URI="${GCC_SRC_URI} d? ( mirror://sourceforge/dgcc/gdc-${D_VER}-src.tar.bz2 )"

	# >= gcc-4.3 uses ecj.jar and we only add gcj as a use flag under certain
	# conditions
	if [[ ${PN} != "kgcc64" && ${PN} != gcc-* ]] ; then
		tc_version_is_at_least "4.3" && \
			GCC_SRC_URI="${GCC_SRC_URI}
			gcj? ( ftp://sourceware.org/pub/java/ecj-${GCC_BRANCH_VER}.jar )"
	fi
	
	# Call get_gcc_src_uri_hardened in hardened-funcs to get
	# Hardened sourcs uri
	get_gcc_src_uri_hardened

	echo "${GCC_SRC_URI}"
}
S=$(gcc_get_s_dir)
SRC_URI=$(get_gcc_src_uri)
#---->> S + SRC_URI essentials >>----


#---->> support checks <<----

# Grab a variable from the build system (taken from linux-info.eclass)
get_make_var() {
	local var=$1 makefile=${2:-${WORKDIR}/build/Makefile}
	echo -e "e:\\n\\t@echo \$(${var})\\ninclude ${makefile}" | \
		r=${makefile%/*} emake --no-print-directory -s -f - 2>/dev/null
}
XGCC() { get_make_var GCC_FOR_TARGET ; }

# This is to make sure we don't accidentally try to enable support for a
# language that doesnt exist. GCC 3.4 supports f77, while 4.0 supports f95, etc.
#
# Also add a hook so special ebuilds (kgcc64) can control which languages
# exactly get enabled
gcc-lang-supported() {
	grep ^language=\"${1}\" "${S}"/gcc/*/config-lang.in > /dev/null || return 1
	[[ -z ${TOOLCHAIN_ALLOWED_LANGS} ]] && return 0
	has $1 ${TOOLCHAIN_ALLOWED_LANGS}
}

#----<< support checks >>----

#---->>env.d logic <<----

create_gcc_env_entry() {
	dodir /etc/env.d/gcc
	local gcc_envd_base="/etc/env.d/gcc/${CTARGET}-${GCC_CONFIG_VER}"

	if [[ -z $1 ]] ; then
		gcc_envd_file="${D}${gcc_envd_base}"
		# I'm leaving the following commented out to remind me that it
		# was an insanely -bad- idea. Stuff broke. GCC_SPECS isnt unset
		# on chroot or in non-toolchain.eclass gcc ebuilds!
		#gcc_specs_file="${LIBPATH}/specs"
		gcc_specs_file=""
	else
		gcc_envd_file="${D}${gcc_envd_base}-$1"
		gcc_specs_file="${LIBPATH}/$1.specs"
	fi

	# phase PATH/ROOTPATH out ...
	echo "PATH=\"${BINPATH}\"" > ${gcc_envd_file}
	echo "ROOTPATH=\"${BINPATH}\"" >> ${gcc_envd_file}
	echo "GCC_PATH=\"${BINPATH}\"" >> ${gcc_envd_file}

	if use multilib && ! has_multilib_profile; then
		LDPATH="${LIBPATH}"
		for path in 32 64 ; do
			[[ -d ${LIBPATH}/${path} ]] && LDPATH="${LDPATH}:${LIBPATH}/${path}"
		done
	else
		local MULTIDIR
		LDPATH="${LIBPATH}"

		# We want to list the default ABI's LIBPATH first so libtool
		# searches that directory first.  This is a temporary
		# workaround for libtool being stupid and using .la's from
		# conflicting ABIs by using the first one in the search path

		local abi=${DEFAULT_ABI}
		local MULTIDIR=$($(XGCC) $(get_abi_CFLAGS ${abi}) --print-multi-directory)
		if [[ ${MULTIDIR} == "." ]] ; then
			LDPATH=${LIBPATH}
		else
			LDPATH=${LIBPATH}/${MULTIDIR}
		fi

		for abi in $(get_all_abis) ; do
			[[ ${abi} == ${DEFAULT_ABI} ]] && continue

			MULTIDIR=$($(XGCC) $(get_abi_CFLAGS ${abi}) --print-multi-directory)
			if [[ ${MULTIDIR} == "." ]] ; then
				LDPATH=${LDPATH}:${LIBPATH}
			else
				LDPATH=${LDPATH}:${LIBPATH}/${MULTIDIR}
			fi
		done
	fi

	echo "LDPATH=\"${LDPATH}\"" >> ${gcc_envd_file}
	echo "MANPATH=\"${DATAPATH}/man\"" >> ${gcc_envd_file}
	echo "INFOPATH=\"${DATAPATH}/info\"" >> ${gcc_envd_file}
	echo "STDCXX_INCDIR=\"${STDCXX_INCDIR##*/}\"" >> ${gcc_envd_file}

	is_crosscompile && echo "CTARGET=${CTARGET}" >> ${gcc_envd_file}

	# Set which specs file to use
	[[ -n ${gcc_specs_file} ]] && echo "GCC_SPECS=\"${gcc_specs_file}\"" >> ${gcc_envd_file}
}

#----<<env.d logic >>----


#---->> pkg_* <<----
gcc_pkg_setup() {
	[[ -z ${ETYPE} ]] && die "Your ebuild needs to set the ETYPE variable"

	#You must build non-hardened compiler with vanilla-spec compiler.
	check_hardened_compiler_vanilla

	if [[ ( $(tc-arch) == "amd64" || $(tc-arch) == "ppc64" ) && ( ${LD_PRELOAD} == "/lib/libsandbox.so" || ${LD_PRELOAD} == "/usr/lib/libsandbox.so" ) ]] && is_multilib ; then
		eerror "Sandbox in your installed portage does not support compilation."
		eerror "of a multilib gcc.	Please set FEATURES=-sandbox and try again."
		eerror "After you have a multilib gcc, re-emerge portage to have a working sandbox."
		die "No 32bit sandbox.	Retry with FEATURES=-sandbox."
	fi

	if [[ ${ETYPE} == "gcc-compiler" ]] ; then
		case $(tc-arch) in
		mips)
			# Must compile for mips64-linux target if we want n32/n64 support
			case "${CTARGET}" in
				mips64*) ;;
				*)
					if use n32 || use n64; then
						eerror "n32/n64 can only be used when target host is mips64*-*-linux-*";
						die "Invalid USE flags for CTARGET ($CTARGET)";
					fi
				;;
			esac

			#cannot have both n32 & n64 without multilib
			if use n32 && use n64 && ! is_multilib; then
				eerror "Please enable multilib if you want to use both n32 & n64";
				die "Invalid USE flag combination";
			fi
		;;
		esac

		# Setup variables which would normally be in the profile
		if is_crosscompile ; then
			multilib_env ${CTARGET}
			if ! use multilib ; then
				MULTILIB_ABIS=${DEFAULT_ABI}
			fi
		fi

		# we dont want to use the installed compiler's specs to build gcc!
		unset GCC_SPECS
	fi
	# Call want_libssp and libc_has_ssp in hardened-funcs
	want_libssp && libc_has_ssp && \
		die "libssp cannot be used with a glibc that has been patched to provide ssp symbols"
}

gcc-compiler_pkg_preinst() {
	:
}

gcc-compiler_pkg_postinst() {

	do_gcc_config

	if ! is_crosscompile ; then
		echo
		ewarn "If you have issues with packages unable to locate libstdc++.la,"
		ewarn "then try running 'fix_libtool_files.sh' on the old gcc versions."
		echo
	fi

	# If our gcc-config version doesn't like '-' in it's version string,
	# tell our users that gcc-config will yell at them, but it's all good.
	if ! has_version '>=sys-devel/gcc-config-1.3.10-r1' && [[ ${GCC_CONFIG_VER/-/} != ${GCC_CONFIG_VER} ]] ; then
		ewarn "Your version of gcc-config will issue about having an invalid profile"
		ewarn "when switching to this profile.	It is safe to ignore this warning,"
		ewarn "and this problem has been corrected in >=sys-devel/gcc-config-1.3.10-r1."
	fi

	if ! is_crosscompile && ! use multislot && [[ ${GCCMAJOR}.${GCCMINOR} == 3.4 ]] ; then
		echo
		ewarn "You should make sure to rebuild all your C++ packages when"
		ewarn "upgrading between different versions of gcc.	 For example,"
		ewarn "when moving to gcc-3.4 from gcc-3.3, emerge gentoolkit and run:"
		ewarn "	 # revdep-rebuild --library libstdc++.so.5"
		echo
		ewarn "For more information on the steps to take when upgrading "
		ewarn "from gcc-3.3 please refer to: "
		ewarn "http://www.gentoo.org/doc/en/gcc-upgrading.xml"
		echo
	fi

	if ! is_crosscompile ; then
		# hack to prevent collisions between SLOT
		[[ ! -d ${ROOT}/lib/rcscripts/awk ]] \
			&& mkdir -p "${ROOT}"/lib/rcscripts/awk
		[[ ! -d ${ROOT}/sbin ]] \
			&& mkdir -p "${ROOT}"/sbin
		cp "${ROOT}/${DATAPATH}"/fixlafiles.awk "${ROOT}"/lib/rcscripts/awk/ || die "installing fixlafiles.awk"
		cp "${ROOT}/${DATAPATH}"/fix_libtool_files.sh "${ROOT}"/sbin/ || die "installing fix_libtool_files.sh"

		[[ ! -d ${ROOT}/usr/bin ]] \
			&& mkdir -p "${ROOT}"/usr/bin
		# Since these aren't critical files and portage sucks with
		# handling of binpkgs, don't require these to be found
		for x in "${ROOT}/${DATAPATH}"/c{89,99} ; do
			if [[ -e ${x} ]]; then
				cp ${x} "${ROOT}"/usr/bin/ || die "installing c89/c99"
			fi
		done
	fi
}

gcc-compiler_pkg_prerm() {
	# Don't let these files be uninstalled #87647
	touch -c "${ROOT}"/sbin/fix_libtool_files.sh \
		"${ROOT}"/lib/rcscripts/awk/fixlafiles.awk
}

gcc-compiler_pkg_postrm() {
	# to make our lives easier (and saner), we do the fix_libtool stuff here.
	# rather than checking SLOT's and trying in upgrade paths, we just see if
	# the common libstdc++.la exists in the ${LIBPATH} of the gcc that we are
	# unmerging.  if it does, that means this was a simple re-emerge.

	# clean up the cruft left behind by cross-compilers
	if is_crosscompile ; then
		if [[ -z $(ls "${ROOT}"/etc/env.d/gcc/${CTARGET}* 2>/dev/null) ]] ; then
			rm -f "${ROOT}"/etc/env.d/gcc/config-${CTARGET}
			rm -f "${ROOT}"/etc/env.d/??gcc-${CTARGET}
			rm -f "${ROOT}"/usr/bin/${CTARGET}-{gcc,{g,c}++}{,32,64}
		fi
		return 0
	fi

	# ROOT isnt handled by the script
	[[ ${ROOT} != "/" ]] && return 0

	if [[ ! -e ${LIBPATH}/libstdc++.so ]] ; then
		einfo "Running 'fix_libtool_files.sh ${GCC_RELEASE_VER}'"
		/sbin/fix_libtool_files.sh ${GCC_RELEASE_VER}
		if [[ -n ${BRANCH_UPDATE} ]] ; then
			einfo "Running 'fix_libtool_files.sh ${GCC_RELEASE_VER}-${BRANCH_UPDATE}'"
			/sbin/fix_libtool_files.sh ${GCC_RELEASE_VER}-${BRANCH_UPDATE}
		fi
	fi

	return 0
}

#---->> pkg_* <<----

#---->> src_* <<----

# generic GCC src_unpack, to be called from the ebuild's src_unpack.
gcc-compiler_src_unpack() {
	# Call hardened_compiler_src_unpack_setup in hardened-funcs
	hardened_compiler_src_unpack_setup

	if is_libffi ; then
		# move the libffi target out of gcj and into all
		sed -i \
			-e '/^libgcj=/s:target-libffi::' \
			-e '/^target_lib/s:=":="target-libffi :' \
			"${S}"/configure || die
	fi
}
gcc-library_src_unpack() {
	:
}
guess_patch_type_in_dir() {
	[[ -n $(ls "$1"/*.bz2 2>/dev/null) ]] \
		&& EPATCH_SUFFIX="patch.bz2" \
		|| EPATCH_SUFFIX="patch"
}
do_gcc_rename_java_bins() {
	# bug #139918 - conflict between gcc and java-config-2 for ownership of
	# /usr/bin/rmi{c,registry}.	 Done with mv & sed rather than a patch
	# because patches would be large (thanks to the rename of man files),
	# and it's clear from the sed invocations that all that changes is the
	# rmi{c,registry} names to grmi{c,registry} names.
	# Kevin F. Quinn 2006-07-12
	einfo "Renaming jdk executables rmic and rmiregistry to grmic and grmiregistry."
	# 1) Move the man files if present (missing prior to gcc-3.4)
	for manfile in rmic rmiregistry; do
		[[ -f ${S}/gcc/doc/${manfile}.1 ]] || continue
		mv ${S}/gcc/doc/${manfile}.1 ${S}/gcc/doc/g${manfile}.1
	done
	# 2) Fixup references in the docs if present (mission prior to gcc-3.4)
	for jfile in gcc/doc/gcj.info gcc/doc/grmic.1 gcc/doc/grmiregistry.1 gcc/java/gcj.texi; do
		[[ -f ${S}/${jfile} ]] || continue
		sed -i -e 's:rmiregistry:grmiregistry:g' ${S}/${jfile} ||
			die "Failed to fixup file ${jfile} for rename to grmiregistry"
		sed -i -e 's:rmic:grmic:g' ${S}/${jfile} ||
			die "Failed to fixup file ${jfile} for rename to grmic"
	done
	# 3) Fixup Makefiles to build the changed executable names
	#	 These are present in all 3.x versions, and are the important bit
	#	 to get gcc to build with the new names.
	for jfile in libjava/Makefile.am libjava/Makefile.in gcc/java/Make-lang.in; do
		sed -i -e 's:rmiregistry:grmiregistry:g' ${S}/${jfile} ||
			die "Failed to fixup file ${jfile} for rename to grmiregistry"
		# Careful with rmic on these files; it's also the name of a directory
		# which should be left unchanged.  Replace occurrences of 'rmic$',
		# 'rmic_' and 'rmic '.
		sed -i -e 's:rmic\([$_ ]\):grmic\1:g' ${S}/${jfile} ||
			die "Failed to fixup file ${jfile} for rename to grmic"
	done
}
gcc_src_unpack() {
	export BRANDING_GCC_PKGVERSION="Gentoo ${GCC_PVR}"

	[[ -z ${UCLIBC_VER} ]] && [[ ${CTARGET} == *-uclibc* ]] && die "Sorry, this version does not support uClibc"

	gcc_quick_unpack
	exclude_gcc_patches
	# Call exclude_hardened_gcc_patches in hardened-funcs
	exclude_hardened_gcc_patches

	cd "${S}"

	if ! use vanilla ; then
		if [[ -n ${PATCH_VER} ]] ; then
			guess_patch_type_in_dir "${WORKDIR}"/patch
			EPATCH_MULTI_MSG="Applying Gentoo patches ..." \
			epatch "${WORKDIR}"/patch
			BRANDING_GCC_PKGVERSION="${BRANDING_GCC_PKGVERSION} p${PATCH_VER}"
		fi
		if [[ -n ${UCLIBC_VER} ]] ; then
			guess_patch_type_in_dir "${WORKDIR}"/uclibc
			EPATCH_MULTI_MSG="Applying uClibc patches ..." \
			epatch "${WORKDIR}"/uclibc
		fi
	fi
	do_gcc_HTB_patches
	# Hardened patches
	# do_gcc_SSP_patches, do_gcc_FORTIFY_patches and do_gcc_PIE_patches is in hardened-funcs
	do_gcc_SSP_patches
	do_gcc_FORTIFY_patches
	do_gcc_PIE_patches
	do_gcc_USER_patches

	${ETYPE}_src_unpack || die "failed to ${ETYPE}_src_unpack"

	# protoize don't build on FreeBSD, skip it
	if ! is_crosscompile && ! use elibc_FreeBSD ; then
		# enable protoize / unprotoize
		sed -i -e '/^LANGUAGES =/s:$: proto:' "${S}"/gcc/Makefile.in
	fi

	fix_files=""
	for x in contrib/test_summary libstdc++-v3/scripts/check_survey.in ; do
		[[ -e ${x} ]] && fix_files="${fix_files} ${x}"
	done
	ht_fix_file ${fix_files} */configure *.sh */Makefile.in

	if ! is_crosscompile && is_multilib && \
	   [[ ( $(tc-arch) == "amd64" || $(tc-arch) == "ppc64" ) && -z ${SKIP_MULTILIB_HACK} ]] ; then
		disgusting_gcc_multilib_HACK || die "multilib hack failed"
	fi

	gcc_version_patch
	if [[ ${GCCMAJOR}.${GCCMINOR} > 4.0 ]] ; then
		if [[ -n ${SNAPSHOT} || -n ${PRERELEASE} ]] ; then
			echo ${PV/_/-} > "${S}"/gcc/BASE-VER
			echo "" > "${S}"/gcc/DATESTAMP
		fi
	fi

	# >= gcc-4.3 doesn't bundle ecj.jar, so copy it
	if [[ ${GCCMAJOR}.${GCCMINOR} > 4.2 ]] &&
		use gcj ; then
		cp -pPR "${DISTDIR}/ecj-${GCC_BRANCH_VER}.jar" "${S}/ecj.jar" || die
	fi

	# disable --as-needed from being compiled into gcc specs
	# natively when using a gcc version < 3.4.4
	# http://gcc.gnu.org/bugzilla/show_bug.cgi?id=14992
	if [[ ${GCCMAJOR} < 3 ]] || \
	   [[ ${GCCMAJOR}.${GCCMINOR} < 3.4 ]] || \
	   [[ ${GCCMAJOR}.${GCCMINOR}.${GCCMICRO} < 3.4.4 ]]
	then
		sed -i -e s/HAVE_LD_AS_NEEDED/USE_LD_AS_NEEDED/g "${S}"/gcc/config.in
	fi

	# In gcc 3.3.x and 3.4.x, rename the java bins to gcc-specific names
	# in line with gcc-4.
	if [[ ${GCCMAJOR} == 3 ]] &&
	   [[ ${GCCMINOR} -ge 3 ]]
	then
		do_gcc_rename_java_bins
	fi

	# Fixup libtool to correctly generate .la files with portage
	cd "${S}"
	elibtoolize --portage --shallow --no-uclibc

	gnuconfig_update

	# update configure files
	local f
	einfo "Fixing misc issues in configure files"
	[[ ${GCCMAJOR} -ge 4 ]] && epatch "${GCC_FILESDIR}"/gcc-configure-texinfo.patch
	for f in $(grep -l 'autoconf version 2.13' $(find "${S}" -name configure)) ; do
		ebegin "  Updating ${f/${S}\/} [LANG]"
		patch "${f}" "${GCC_FILESDIR}"/gcc-configure-LANG.patch >& "${T}"/configure-patch.log \
			|| eerror "Please file a bug about this"
		eend $?
	done
	sed -i 's|A-Za-z0-9|[:alnum:]|g' "${S}"/gcc/*.awk #215828

	if [[ -x contrib/gcc_update ]] ; then
		einfo "Touching generated files"
		./contrib/gcc_update --touch | \
			while read f ; do
				einfo "  ${f%%...}"
			done
	fi

	disable_multilib_libjava || die "failed to disable multilib java"
}

gcc-library-configure() {
	# multilib support
	[[ ${GCC_TARGET_NO_MULTILIB} == "true" ]] \
		&& confgcc="${confgcc} --disable-multilib" \
		|| confgcc="${confgcc} --enable-multilib"
}

gcc-compiler-configure() {
	# multilib support
	if is_multilib ; then
		confgcc="${confgcc} --enable-multilib"
	elif [[ ${CTARGET} == *-linux* ]] ; then
		confgcc="${confgcc} --disable-multilib"
	fi

	if tc_version_is_at_least "4.0" ; then
		if has mudflap ${IUSE} ; then
			confgcc="${confgcc} $(use_enable mudflap libmudflap)"
		else
			confgcc="${confgcc} --disable-libmudflap"
		fi
		# Call hardened_configure in hardened-funcs
		hardened_configure
		
		if tc_version_is_at_least "4.2" ; then
			confgcc="${confgcc} $(use_enable openmp libgomp)"
		fi

		# enable the cld workaround until we move things to stable.
		# by that point, the rest of the software out there should
		# have caught up.
		if tc_version_is_at_least "4.3" ; then
			if ! has ${ARCH} ${KEYWORDS} ; then
				confgcc="${confgcc} --enable-cld"
			fi
		fi
	fi

	# GTK+ is preferred over xlib in 3.4.x (xlib is unmaintained
	# right now). Much thanks to <csm@gnu.org> for the heads up.
	# Travis Tilley <lv@gentoo.org>	 (11 Jul 2004)
	if ! is_gcj ; then
		confgcc="${confgcc} --disable-libgcj"
	elif use gtk ; then
		confgcc="${confgcc} --enable-java-awt=gtk"
	fi

	case $(tc-arch) in
		# Add --with-abi flags to set default MIPS ABI
		mips)
			local mips_abi=""
			use n64 && mips_abi="--with-abi=64"
			use n32 && mips_abi="--with-abi=n32"
			[[ -n ${mips_abi} ]] && confgcc="${confgcc} ${mips_abi}"
			;;
		# Default arch for x86 is normally i386, lets give it a bump
		# since glibc will do so based on CTARGET anyways
		x86)
			confgcc="${confgcc} --with-arch=${CTARGET%%-*}"
			;;
		# Enable sjlj exceptions for backward compatibility on hppa
		hppa)
			[[ ${GCCMAJOR} == "3" ]] && confgcc="${confgcc} --enable-sjlj-exceptions"
			;;
	esac

	GCC_LANG="c"
	is_cxx && GCC_LANG="${GCC_LANG},c++"
	is_d   && GCC_LANG="${GCC_LANG},d"
	is_gcj && GCC_LANG="${GCC_LANG},java"
	if is_objc || is_objcxx ; then
		GCC_LANG="${GCC_LANG},objc"
		if tc_version_is_at_least "4.0" ; then
			use objc-gc && confgcc="${confgcc} --enable-objc-gc"
		fi
		is_objcxx && GCC_LANG="${GCC_LANG},obj-c++"
	fi
	is_treelang && GCC_LANG="${GCC_LANG},treelang"

	# fortran support just got sillier! the lang value can be f77 for
	# fortran77, f95 for fortran95, or just plain old fortran for the
	# currently supported standard depending on gcc version.
	is_fortran && GCC_LANG="${GCC_LANG},fortran"
	is_f77 && GCC_LANG="${GCC_LANG},f77"
	is_f95 && GCC_LANG="${GCC_LANG},f95"

	# We do NOT want 'ADA support' in here!
	# is_ada && GCC_LANG="${GCC_LANG},ada"

	einfo "configuring for GCC_LANG: ${GCC_LANG}"
}

# Other than the variables described for gcc_setup_variables, the following
# will alter tha behavior of gcc_do_configure:
#
#	CTARGET
#	CBUILD
#			Enable building for a target that differs from CHOST
#
#	GCC_TARGET_NO_MULTILIB
#			Disable multilib. Useful when building single library targets.
#
#	GCC_LANG
#			Enable support for ${GCC_LANG} languages. defaults to just "c"
#
# Travis Tilley <lv@gentoo.org> (04 Sep 2004)
#
gcc_do_configure() {
	local confgcc

	# Set configuration based on path variables
	confgcc="${confgcc} \
		--prefix=${PREFIX} \
		--bindir=${BINPATH} \
		--includedir=${INCLUDEPATH} \
		--datadir=${DATAPATH} \
		--mandir=${DATAPATH}/man \
		--infodir=${DATAPATH}/info \
		--with-gxx-include-dir=${STDCXX_INCDIR}"

	# All our cross-compile logic goes here !  woo !
	confgcc="${confgcc} --host=${CHOST}"
	if is_crosscompile || tc-is-cross-compiler ; then
		# Straight from the GCC install doc:
		# "GCC has code to correctly determine the correct value for target
		# for nearly all native systems. Therefore, we highly recommend you
		# not provide a configure target when configuring a native compiler."
		confgcc="${confgcc} --target=${CTARGET}"
	fi
	[[ -n ${CBUILD} ]] && confgcc="${confgcc} --build=${CBUILD}"

	# ppc altivec support
	confgcc="${confgcc} $(use_enable altivec)"

	# gcc has fixed-point arithmetic support in 4.3 for mips targets that can
	# significantly increase compile time by several hours.  This will allow
	# users to control this feature in the event they need the support.
	tc_version_is_at_least "4.3" && confgcc="${confgcc} $(use_enable fixed-point)"


	[[ $(tc-is-softfloat) == "yes" ]] && confgcc="${confgcc} --with-float=soft"

	# Native Language Support
	if use nls ; then
		confgcc="${confgcc} --enable-nls --without-included-gettext"
	else
		confgcc="${confgcc} --disable-nls"
	fi

	# reasonably sane globals (hopefully)
	confgcc="${confgcc} \
		--with-system-zlib \
		--disable-checking \
		--disable-werror \
		--enable-secureplt"

	# etype specific configuration
	einfo "running ${ETYPE}-configure"
	${ETYPE}-configure || die

	# if not specified, assume we are building for a target that only
	# requires C support
	GCC_LANG=${GCC_LANG:-c}
	confgcc="${confgcc} --enable-languages=${GCC_LANG}"

	if is_crosscompile ; then
		# When building a stage1 cross-compiler (just C compiler), we have to
		# disable a bunch of features or gcc goes boom
		local needed_libc=""
		case ${CTARGET} in
			*-linux)		 needed_libc=no-fucking-clue;;
			*-dietlibc)		 needed_libc=dietlibc;;
			*-elf)			 needed_libc=newlib;;
			*-freebsd*)		 needed_libc=freebsd-lib;;
			*-gnu*)			 needed_libc=glibc;;
			*-klibc)		 needed_libc=klibc;;
			*-uclibc*)		 needed_libc=uclibc;;
			*-cygwin)        needed_libc=cygwin;;
			mingw*|*-mingw*) needed_libc=mingw-runtime;;
			avr)			 confgcc="${confgcc} --enable-shared --disable-threads";;
		esac
		if [[ -n ${needed_libc} ]] ; then
			if ! has_version ${CATEGORY}/${needed_libc} ; then
				confgcc="${confgcc} --disable-shared --disable-threads --without-headers"
			elif built_with_use --hidden --missing false ${CATEGORY}/${needed_libc} crosscompile_opts_headers-only ; then
				confgcc="${confgcc} --disable-shared --with-sysroot=${PREFIX}/${CTARGET}"
			else
				confgcc="${confgcc} --with-sysroot=${PREFIX}/${CTARGET}"
			fi
		fi

		if [[ ${GCCMAJOR}.${GCCMINOR} > 4.1 ]] ; then
			confgcc="${confgcc} --disable-bootstrap --disable-libgomp"
		fi
	elif [[ ${CHOST} == mingw* ]] || [[ ${CHOST} == *-mingw* ]] || [[ ${CHOST} == *-cygwin ]] ; then
		confgcc="${confgcc} --enable-shared --enable-threads=win32"
	else
		confgcc="${confgcc} --enable-shared --enable-threads=posix"
	fi
	[[ ${CTARGET} == *-elf ]] && confgcc="${confgcc} --with-newlib"
	# __cxa_atexit is "essential for fully standards-compliant handling of
	# destructors", but apparently requires glibc.
	if [[ ${CTARGET} == *-uclibc* ]] ; then
		confgcc="${confgcc} --disable-__cxa_atexit --enable-target-optspace"
		[[ ${GCCMAJOR}.${GCCMINOR} == 3.3 ]] && confgcc="${confgcc} --enable-sjlj-exceptions"
		[[ ${GCCMAJOR}.${GCCMINOR} > 3.3 ]] && confgcc="${confgcc} --enable-clocale=uclibc"
	elif [[ ${CTARGET} == *-gnu* ]] ; then
		confgcc="${confgcc} --enable-__cxa_atexit"
		confgcc="${confgcc} --enable-clocale=gnu"
	elif [[ ${CTARGET} == *-freebsd* ]]; then
		confgcc="${confgcc} --enable-__cxa_atexit"
	fi
	[[ ${GCCMAJOR}.${GCCMINOR} < 3.4 ]] && confgcc="${confgcc} --disable-libunwind-exceptions"

	# create a sparc*linux*-{gcc,g++} that can handle -m32 and -m64 (biarch)
	if [[ ${CTARGET} == sparc*linux* ]] \
		&& is_multilib \
		&& [[ ${GCCMAJOR}.${GCCMINOR} > 4.2 ]]
	then
		confgcc="${confgcc} --enable-targets=all"
	fi

	tc_version_is_at_least 4.3 && set -- "$@" \
		--with-bugurl=http://bugs.gentoo.org/ \
		--with-pkgversion="${BRANDING_GCC_PKGVERSION}"
	set -- ${confgcc} "$@" ${EXTRA_ECONF}

	# Nothing wrong with a good dose of verbosity
	echo
	einfo "PREFIX:			${PREFIX}"
	einfo "BINPATH:			${BINPATH}"
	einfo "LIBPATH:			${LIBPATH}"
	einfo "DATAPATH:		${DATAPATH}"
	einfo "STDCXX_INCDIR:	${STDCXX_INCDIR}"
	echo
	einfo "Configuring GCC with: ${@//--/\n\t--}"
	echo

	# Build in a separate build tree
	mkdir -p "${WORKDIR}"/build
	pushd "${WORKDIR}"/build > /dev/null

	# and now to do the actual configuration
	addwrite /dev/zero
	echo "${S}"/configure "$@"
	"${S}"/configure "$@" || die "failed to run configure"

	# return to whatever directory we were in before
	popd > /dev/null
}

# This function accepts one optional argument, the make target to be used.
# If ommitted, gcc_do_make will try to guess whether it should use all,
# profiledbootstrap, or bootstrap-lean depending on CTARGET and arch. An
# example of how to use this function:
#
#	gcc_do_make all-target-libstdc++-v3
#
# In addition to the target to be used, the following variables alter the
# behavior of this function:
#
#	LDFLAGS
#			Flags to pass to ld
#
#	STAGE1_CFLAGS
#			CFLAGS to use during stage1 of a gcc bootstrap
#
#	BOOT_CFLAGS
#			CFLAGS to use during stages 2+3 of a gcc bootstrap.
#
# Travis Tilley <lv@gentoo.org> (04 Sep 2004)
#
gcc_do_make() {
	# Fix for libtool-portage.patch
	local OLDS=${S}
	S=${WORKDIR}/build

	# Set make target to $1 if passed
	[[ -n $1 ]] && GCC_MAKE_TARGET=$1
	# default target
	if is_crosscompile || tc-is-cross-compiler ; then
		# 3 stage bootstrapping doesnt quite work when you cant run the
		# resulting binaries natively ^^;
		GCC_MAKE_TARGET=${GCC_MAKE_TARGET-all}
	else
		GCC_MAKE_TARGET=${GCC_MAKE_TARGET-bootstrap-lean}
	fi

	# the gcc docs state that parallel make isnt supported for the
	# profiledbootstrap target, as collisions in profile collecting may occur.
	[[ ${GCC_MAKE_TARGET} == "profiledbootstrap" ]] && export MAKEOPTS="${MAKEOPTS} -j1"

	# boundschecking seems to introduce parallel build issues
	want_boundschecking && export MAKEOPTS="${MAKEOPTS} -j1"

	if [[ ${GCC_MAKE_TARGET} == "all" ]] ; then
		STAGE1_CFLAGS=${STAGE1_CFLAGS-"${CFLAGS}"}
	elif [[ $(gcc-version) == "3.4" && ${GCC_BRANCH_VER} == "3.4" ]] && gcc-specs-ssp ; then
		# See bug #79852
		STAGE1_CFLAGS=${STAGE1_CFLAGS-"-O2"}
	else
		STAGE1_CFLAGS=${STAGE1_CFLAGS-"-O"}
	fi

	if is_crosscompile; then
		# In 3.4, BOOT_CFLAGS is never used on a crosscompile...
		# but I'll leave this in anyways as someone might have had
		# some reason for putting it in here... --eradicator
		BOOT_CFLAGS=${BOOT_CFLAGS-"-O2"}
	else
		# we only want to use the system's CFLAGS if not building a
		# cross-compiler.
		BOOT_CFLAGS=${BOOT_CFLAGS-"$(get_abi_CFLAGS) ${CFLAGS}"}
	fi

	pushd "${WORKDIR}"/build
	
	emake \
		LDFLAGS="${LDFLAGS}" \
		STAGE1_CFLAGS="${STAGE1_CFLAGS}" \
		LIBPATH="${LIBPATH}" \
		BOOT_CFLAGS="${BOOT_CFLAGS}" \
		${GCC_MAKE_TARGET} \
		|| die "emake failed with ${GCC_MAKE_TARGET}"

	if ! is_crosscompile && ! use nocxx && use doc ; then
		if type -p doxygen > /dev/null ; then
			if tc_version_is_at_least 4.3 ; then
				cd "${CTARGET}"/libstdc++-v3/doc
				emake doc-man-doxygen || ewarn "failed to make docs"
			elif tc_version_is_at_least 3.0 ; then
				cd "${CTARGET}"/libstdc++-v3
				emake doxygen-man || ewarn "failed to make docs"
			fi
		else
			ewarn "Skipping libstdc++ manpage generation since you don't have doxygen installed"
		fi
	fi

	popd
}

# This function will add ${GCC_CONFIG_VER} to the names of all shared libraries in the
# directory specified to avoid filename collisions between multiple slotted
# non-versioned gcc targets. If no directory is specified, it is assumed that
# you want -all- shared objects to have ${GCC_CONFIG_VER} added. Example
#
#	add_version_to_shared ${D}/usr/$(get_libdir)
#
# Travis Tilley <lv@gentoo.org> (05 Sep 2004)
#
add_version_to_shared() {
	local sharedlib sharedlibdir
	[[ -z $1 ]] \
		&& sharedlibdir=${D} \
		|| sharedlibdir=$1

	for sharedlib in $(find ${sharedlibdir} -name *.so.*) ; do
		if [[ ! -L ${sharedlib} ]] ; then
			einfo "Renaming `basename "${sharedlib}"` to `basename "${sharedlib/.so*/}-${GCC_CONFIG_VER}.so.${sharedlib/*.so./}"`"
			mv "${sharedlib}" "${sharedlib/.so*/}-${GCC_CONFIG_VER}.so.${sharedlib/*.so./}" \
				|| die
			pushd `dirname "${sharedlib}"` > /dev/null || die
			ln -sf "`basename "${sharedlib/.so*/}-${GCC_CONFIG_VER}.so.${sharedlib/*.so./}"`" \
				"`basename "${sharedlib}"`" || die
			popd > /dev/null || die
		fi
	done
}

# This is mostly a stub function to be overwritten in an ebuild
gcc_do_filter_flags() {
	strip-flags

	# In general gcc does not like optimization, and add -O2 where
	# it is safe.  This is especially true for gcc 3.3 + 3.4
	replace-flags -O? -O2

	# ... sure, why not?
	strip-unsupported-flags

	# dont want to funk ourselves
	filter-flags '-mabi*' -m31 -m32 -m64

	case ${GCC_BRANCH_VER} in
	3.2|3.3)
		case $(tc-arch) in
			x86)   filter-flags '-mtune=*';;
			amd64) filter-flags '-mtune=*'
				replace-cpu-flags k8 athlon64 opteron i686;;
		esac
		;;
	3.4|4.*)
		case $(tc-arch) in
			x86|amd64) filter-flags '-mcpu=*';;
		esac
		;;
	esac

	# Compile problems with these (bug #6641 among others)...
	#filter-flags "-fno-exceptions -fomit-frame-pointer -fforce-addr"

	# CFLAGS logic (verified with 3.4.3):
	# CFLAGS:
	#	This conflicts when creating a crosscompiler, so set to a sane
	#	  default in this case:
	#	used in ./configure and elsewhere for the native compiler
	#	used by gcc when creating libiberty.a
	#	used by xgcc when creating libstdc++ (and probably others)!
	#	  this behavior should be removed...
	#
	# CXXFLAGS:
	#	used by xgcc when creating libstdc++
	#
	# STAGE1_CFLAGS (not used in creating a crosscompile gcc):
	#	used by ${CHOST}-gcc for building stage1 compiler
	#
	# BOOT_CFLAGS (not used in creating a crosscompile gcc):
	#	used by xgcc for building stage2/3 compiler

	if is_crosscompile ; then
		# Set this to something sane for both native and target
		CFLAGS="-O2 -pipe"

		local VAR="CFLAGS_"${CTARGET//-/_}
		CXXFLAGS=${!VAR}
	fi

	export GCJFLAGS=${GCJFLAGS:-${CFLAGS}}
}

gcc_src_compile() {
	gcc_do_filter_flags
	einfo "CFLAGS=\"${CFLAGS}\""
	einfo "CXXFLAGS=\"${CXXFLAGS}\""
	
	# Call setup_minispecs_gcc_build_specs in hardened-funcs
	# For hardened gcc 4 for build the hardened specs file to use when building gcc
	setup_minispecs_gcc_build_specs

	# Build in a separate build tree
	mkdir -p "${WORKDIR}"/build
	pushd "${WORKDIR}"/build > /dev/null

	# Install our pre generated manpages if we do not have perl ...
	[[ ! -x /usr/bin/perl ]] && [[ -n ${MAN_VER} ]] && \
		unpack gcc-${MAN_VER}-manpages.tar.bz2

	einfo "Configuring ${PN} ..."
	gcc_do_configure

	touch "${S}"/gcc/c-gperf.h

	# Do not make manpages if we do not have perl ...
	[[ ! -x /usr/bin/perl ]] \
		&& find "${WORKDIR}"/build -name '*.[17]' | xargs touch

	einfo "Compiling ${PN} ..."
	gcc_do_make ${GCC_MAKE_TARGET}
	
	# Call setup_split_specs in hardened-funcs
	# Setup Hardened Split specs for gcc 3.4
	setup_split_specs

	popd > /dev/null
}

gcc_src_test() {
	cd "${WORKDIR}"/build
	emake -j1 -k check || ewarn "check failed and that sucks :("
}

gcc-library_src_install() {
	# Do the 'make install' from the build directory
	cd "${WORKDIR}"/build
	S=${WORKDIR}/build \
	emake -j1 \
		DESTDIR="${D}" \
		prefix=${PREFIX} \
		bindir=${BINPATH} \
		includedir=${LIBPATH}/include \
		datadir=${DATAPATH} \
		mandir=${DATAPATH}/man \
		infodir=${DATAPATH}/info \
		LIBPATH="${LIBPATH}" \
		${GCC_INSTALL_TARGET} || die

	if [[ ${GCC_LIB_COMPAT_ONLY} == "true" ]] ; then
		rm -rf "${D}"${INCLUDEPATH}
		rm -rf "${D}"${DATAPATH}
		pushd "${D}"${LIBPATH}/
		rm *.a *.la *.so
		popd
	fi

	if [[ -n ${GCC_LIB_USE_SUBDIR} ]] ; then
		mkdir -p "${WORKDIR}"/${GCC_LIB_USE_SUBDIR}/
		mv "${D}"${LIBPATH}/* "${WORKDIR}"/${GCC_LIB_USE_SUBDIR}/
		mv "${WORKDIR}"/${GCC_LIB_USE_SUBDIR}/ "${D}"${LIBPATH}

		dodir /etc/env.d
		echo "LDPATH=\"${LIBPATH}/${GCC_LIB_USE_SUBDIR}/\"" >> "${D}"/etc/env.d/99${PN}
	fi

	if [[ ${GCC_VAR_TYPE} == "non-versioned" ]] ; then
		# if we're not using versioned directories, we need to use versioned
		# filenames.
		add_version_to_shared
	fi
}

gcc-compiler_src_install() {
	local x=
	cd "${WORKDIR}"/build

	# Do allow symlinks in private gcc include dir as this can break the build
	find gcc/include*/ -type l -print0 | xargs rm -f

	# Remove generated headers, as they can cause things to break
	# (ncurses, openssl, etc).
	for x in $(find gcc/include*/ -name '*.h') ; do
		grep -q 'It has been auto-edited by fixincludes from' "${x}" \
			&& rm -f "${x}"
	done
	# Do the 'make install' from the build directory
	S=${WORKDIR}/build \
	emake -j1 DESTDIR="${D}" install || die
	# Punt some tools which are really only useful while building gcc
	find "${D}" -name install-tools -prune -type d -exec rm -rf "{}" \;
	# This one comes with binutils
	find "${D}" -name libiberty.a -exec rm -f "{}" \;

	# Move the libraries to the proper location
	gcc_movelibs

	# Basic sanity check
	if ! is_crosscompile ; then
		local EXEEXT
		eval $(grep ^EXEEXT= "${WORKDIR}"/build/gcc/config.log)
		[[ -r ${D}${BINPATH}/gcc${EXEEXT} ]] || die "gcc not found in ${D}"
	fi

	dodir /etc/env.d/gcc
	create_gcc_env_entry
	# Call create_hardened_gcc_env_entry in hardened-funcs
	create_hardened_gcc_env_entry
		
	# Make sure we dont have stuff lying around that
	# can nuke multiple versions of gcc
	gcc_slot_java
	
	# Move <cxxabi.h> to compiler-specific directories
	[[ -f ${D}${STDCXX_INCDIR}/cxxabi.h ]] && \
		mv -f "${D}"${STDCXX_INCDIR}/cxxabi.h "${D}"${LIBPATH}/include/

	# These should be symlinks
	dodir /usr/bin
	cd "${D}"${BINPATH}
	for x in cpp gcc g++ c++ g77 gcj gcjh gfortran ; do
		# For some reason, g77 gets made instead of ${CTARGET}-g77...
		# this should take care of that
		[[ -f ${x} ]] && mv ${x} ${CTARGET}-${x}

		if [[ -f ${CTARGET}-${x} ]] && ! is_crosscompile ; then
			ln -sf ${CTARGET}-${x} ${x}

			# Create version-ed symlinks
			dosym ${BINPATH}/${CTARGET}-${x} \
				/usr/bin/${CTARGET}-${x}-${GCC_CONFIG_VER}
			dosym ${BINPATH}/${CTARGET}-${x} \
				/usr/bin/${x}-${GCC_CONFIG_VER}
		fi

		if [[ -f ${CTARGET}-${x}-${GCC_CONFIG_VER} ]] ; then
			rm -f ${CTARGET}-${x}-${GCC_CONFIG_VER}
			ln -sf ${CTARGET}-${x} ${CTARGET}-${x}-${GCC_CONFIG_VER}
		fi
	done

	# I do not know if this will break gcj stuff, so I'll only do it for
	#	objc for now; basically "ffi.h" is the correct file to include,
	#	but it gets installed in .../GCCVER/include and yet it does
	#	"#include <ffitarget.h>" which (correctly, as it's an "extra" file)
	#	is installed in .../GCCVER/include/libffi; the following fixes
	#	ffi.'s include of ffitarget.h - Armando Di Cianno <fafhrd@gentoo.org>
	if [[ -d ${D}${LIBPATH}/include/libffi ]] ; then
		mv -i "${D}"${LIBPATH}/include/libffi/* "${D}"${LIBPATH}/include || die
		rm -r "${D}"${LIBPATH}/include/libffi || die
	fi

	# Now do the fun stripping stuff
	env RESTRICT="" CHOST=${CHOST} prepstrip "${D}${BINPATH}"
	env RESTRICT="" CHOST=${CTARGET} prepstrip "${D}${LIBPATH}"
	# gcc used to install helper binaries in lib/ but then moved to libexec/
	[[ -d ${D}${PREFIX}/libexec/gcc ]] && \
		env RESTRICT="" CHOST=${CHOST} prepstrip "${D}${PREFIX}/libexec/gcc/${CTARGET}/${GCC_CONFIG_VER}"

	cd "${S}"
	if is_crosscompile; then
		rm -rf "${D}"/usr/share/{man,info}
		rm -rf "${D}"${DATAPATH}/{man,info}
	else
		local cxx_mandir=${WORKDIR}/build/${CTARGET}/libstdc++-v3/docs/doxygen/man
		if [[ -d ${cxx_mandir} ]] ; then
			# clean bogus manpages #113902
			find "${cxx_mandir}" -name '*_build_*' -exec rm {} \;
			cp -r "${cxx_mandir}"/man? "${D}/${DATAPATH}"/man/
		fi
		has noinfo ${FEATURES} \
			&& rm -r "${D}/${DATAPATH}"/info \
			|| prepinfo "${DATAPATH}"
		has noman ${FEATURES} \
			&& rm -r "${D}/${DATAPATH}"/man \
			|| prepman "${DATAPATH}"
	fi
	# prune empty dirs left behind
	for x in 1 2 3 4 ; do
		find "${D}" -type d -exec rmdir "{}" \; >& /dev/null
	done

	# install testsuite results
	if use test; then
		docinto testsuite
		find "${WORKDIR}"/build -type f -name "*.sum" -print0 | xargs -0 dodoc
		find "${WORKDIR}"/build -type f -path "*/testsuite/*.log" -print0 \
			| xargs -0 dodoc
	fi

	# Rather install the script, else portage with changing $FILESDIR
	# between binary and source package borks things ....
	if ! is_crosscompile ; then
		insinto "${DATAPATH}"
		if tc_version_is_at_least 4.0 ; then
			newins "${GCC_FILESDIR}"/awk/fixlafiles.awk-no_gcc_la fixlafiles.awk || die
			find "${D}/${LIBPATH}" -name libstdc++.la -type f -exec rm "{}" \;
		else
			doins "${GCC_FILESDIR}"/awk/fixlafiles.awk || die
		fi
		exeinto "${DATAPATH}"
		doexe "${GCC_FILESDIR}"/fix_libtool_files.sh || die
		doexe "${GCC_FILESDIR}"/c{89,99} || die
	fi

	# use gid of 0 because some stupid ports don't have
	# the group 'root' set to gid 0
	chown -R root:0 "${D}"${LIBPATH}
	
	# Call copy_minispecs_gcc_specs in hardened-funcs
	# Make the "specs" file for hardened gcc 4
	# and copy the minispecs
	copy_minispecs_gcc_specs
}
gcc_slot_java() {
	local x
	
	# Move Java headers to compiler-specific dir
		for x in "${D}"${PREFIX}/include/gc*.h "${D}"${PREFIX}/include/j*.h ; do
			[[ -f ${x} ]] && mv -f "${x}" "${D}"${LIBPATH}/include/
		done
		for x in gcj gnu java javax org ; do
			if [[ -d ${D}${PREFIX}/include/${x} ]] ; then
				dodir /${LIBPATH}/include/${x}
				mv -f "${D}"${PREFIX}/include/${x}/* "${D}"${LIBPATH}/include/${x}/
				rm -rf "${D}"${PREFIX}/include/${x}
			fi
		done
		if [[ -d ${D}${PREFIX}/lib/security ]] || [[ -d ${D}${PREFIX}/$(get_libdir)/security ]] ; then
			dodir /${LIBPATH}/security
			mv -f "${D}"${PREFIX}/lib*/security/* "${D}"${LIBPATH}/security
			rm -rf "${D}"${PREFIX}/lib*/security
		fi

		# Move libgcj.spec to compiler-specific directories
		[[ -f ${D}${PREFIX}/lib/libgcj.spec ]] && \
		mv -f "${D}"${PREFIX}/lib/libgcj.spec "${D}"${LIBPATH}/libgcj.spec

		# SLOT up libgcj.pc (and let gcc-config worry about links)
		local libgcj=$(find "${D}"${PREFIX}/lib/pkgconfig/ -name 'libgcj*.pc')
		if [[ -n ${libgcj} ]] ; then
			sed -i "/^libdir=/s:=.*:=${LIBPATH}:" "${libgcj}"
			mv "${libgcj}" "${D}"/usr/lib/pkgconfig/libgcj-${GCC_PV}.pc || die
		fi

		# Rename jar because it could clash with Kaffe's jar if this gcc is
		# primary compiler (aka don't have the -<version> extension)
		cd "${D}"${BINPATH}
		[[ -f jar ]] && mv -f jar gcj-jar
}
# Move around the libs to the right location.  For some reason,
# when installing gcc, it dumps internal libraries into /usr/lib
# instead of the private gcc lib path
gcc_movelibs() {
	# older versions of gcc did not support --print-multi-os-directory
	tc_version_is_at_least 3.0 || return 0

	local multiarg removedirs=""
	for multiarg in $($(XGCC) -print-multi-lib) ; do
		multiarg=${multiarg#*;}
		multiarg=${multiarg//@/ -}

		local OS_MULTIDIR=$($(XGCC) ${multiarg} --print-multi-os-directory)
		local MULTIDIR=$($(XGCC) ${multiarg} --print-multi-directory)
		local TODIR=${D}${LIBPATH}/${MULTIDIR}
		local FROMDIR=

		[[ -d ${TODIR} ]] || mkdir -p ${TODIR}

		for FROMDIR in \
			${LIBPATH}/${OS_MULTIDIR} \
			${LIBPATH}/../${MULTIDIR} \
			${PREFIX}/lib/${OS_MULTIDIR} \
			${PREFIX}/${CTARGET}/lib/${OS_MULTIDIR} \
			${PREFIX}/lib/${MULTIDIR}
		do
			removedirs="${removedirs} ${FROMDIR}"
			FROMDIR=${D}${FROMDIR}
			if [[ ${FROMDIR} != "${TODIR}" && -d ${FROMDIR} ]] ; then
				local files=$(find "${FROMDIR}" -maxdepth 1 ! -type d 2>/dev/null)
				if [[ -n ${files} ]] ; then
					mv ${files} "${TODIR}"
				fi
			fi
		done
	done

	# We remove directories separately to avoid this case:
	#	mv SRC/lib/../lib/*.o DEST
	#	rmdir SRC/lib/../lib/
	#	mv SRC/lib/../lib32/*.o DEST  # Bork
	for FROMDIR in ${removedirs} ; do
		rmdir "${D}"${FROMDIR} >& /dev/null
	done
	find "${D}" -type d | xargs rmdir >& /dev/null

	fix_libtool_libdir_paths $(find "${D}"${LIBPATH} -name *.la)
}

#----<< src_* >>----

#---->> unorganized crap in need of refactoring follows

# gcc_quick_unpack will unpack the gcc tarball and patches in a way that is
# consistant with the behavior of get_gcc_src_uri. The only patch it applies
# itself is the branch update if present.
#
# Travis Tilley <lv@gentoo.org> (03 Sep 2004)
#
gcc_quick_unpack() {
	pushd "${WORKDIR}" > /dev/null
	export PATCH_GCC_VER=${PATCH_GCC_VER:-${GCC_RELEASE_VER}}
	export UCLIBC_GCC_VER=${UCLIBC_GCC_VER:-${PATCH_GCC_VER}}
	export HTB_GCC_VER=${HTB_GCC_VER:-${GCC_RELEASE_VER}}
	
	if [[ -n ${GCC_A_FAKEIT} ]] ; then
		unpack ${GCC_A_FAKEIT}
	elif [[ -n ${PRERELEASE} ]] ; then
		unpack gcc-${PRERELEASE}.tar.bz2
	elif [[ -n ${SNAPSHOT} ]] ; then
		unpack gcc-${SNAPSHOT}.tar.bz2
	else
		unpack gcc-${GCC_RELEASE_VER}.tar.bz2
		# We want branch updates to be against a release tarball
		if [[ -n ${BRANCH_UPDATE} ]] ; then
			pushd "${S}" > /dev/null
			epatch ${DISTDIR}/gcc-${GCC_RELEASE_VER}-branch-update-${BRANCH_UPDATE}.patch.bz2
			popd > /dev/null
		fi
	fi

	if [[ -n ${D_VER} ]] && use d ; then
		pushd "${S}"/gcc > /dev/null
		unpack gdc-${D_VER}-src.tar.bz2
		cd ..
		ebegin "Adding support for the D language"
		./gcc/d/setup-gcc.sh >& "${T}"/dgcc.log
		if ! eend $? ; then
			eerror "The D gcc package failed to apply"
			eerror "Please include this log file when posting a bug report:"
			eerror "  ${T}/dgcc.log"
			die "failed to include the D language"
		fi
		popd > /dev/null
	fi

	[[ -n ${PATCH_VER} ]] && \
		unpack gcc-${PATCH_GCC_VER}-patches-${PATCH_VER}.tar.bz2

	[[ -n ${UCLIBC_VER} ]] && \
		unpack gcc-${UCLIBC_GCC_VER}-uclibc-patches-${UCLIBC_VER}.tar.bz2

	want_boundschecking && \
		unpack "bounds-checking-gcc-${HTB_GCC_VER}-${HTB_VER}.patch.bz2"
	
	# Call hardened_gcc_quick_unpack in hardened-funcs
	hardened_gcc_quick_unpack

	popd > /dev/null
}

# Exclude any unwanted patches, as specified by the following variables:
#
#	GENTOO_PATCH_EXCLUDE
#			List of filenames, relative to ${WORKDIR}/patch/
#
# Travis Tilley <lv@gentoo.org> (03 Sep 2004)
#
exclude_gcc_patches() {
	local i
	for i in ${GENTOO_PATCH_EXCLUDE} ; do
		if [[ -f ${WORKDIR}/patch/${i} ]] ; then
			einfo "Excluding patch ${i}"
			rm -f "${WORKDIR}"/patch/${i} || die "failed to delete ${i}"
		fi
	done
}

do_gcc_HTB_patches() {
	if ! want_boundschecking || \
	   (want_ssp && [[ ${HTB_EXCLUSIVE} == "true" ]])
	then
		do_gcc_stub htb
		return 0
	fi

	# modify the bounds checking patch with a regression patch
	epatch "${WORKDIR}/bounds-checking-gcc-${HTB_GCC_VER}-${HTB_VER}.patch"
	BRANDING_GCC_PKGVERSION="${BRANDING_GCC_PKGVERSION}, HTB-${HTB_GCC_VER}-${HTB_VER}"
}
do_gcc_USER_patches() {
	local check base=${PORTAGE_CONFIGROOT}/etc/portage/patches
	for check in {${CATEGORY}/${PF},${CATEGORY}/${P},${CATEGORY}/${PN}}; do
		EPATCH_SOURCE=${base}/${CTARGET}/${check}
		[[ -r ${EPATCH_SOURCE} ]] || EPATCH_SOURCE=${base}/${CHOST}/${check}
		[[ -r ${EPATCH_SOURCE} ]] || EPATCH_SOURCE=${base}/${check}
		if [[ -d ${EPATCH_SOURCE} ]] ; then
			EPATCH_SUFFIX="patch"
			EPATCH_FORCE="yes" \
			EPATCH_MULTI_MSG="Applying user patches from ${EPATCH_SOURCE} ..." \
			epatch
			break
		fi
	done
}
should_we_gcc_config() {
	# we always want to run gcc-config if we're bootstrapping, otherwise
	# we might get stuck with the c-only stage1 compiler
	use bootstrap && return 0
	use build && return 0

	# if the current config is invalid, we definitely want a new one
	# Note: due to bash quirkiness, the following must not be 1 line
	local curr_config
	curr_config=$(env -i ROOT="${ROOT}" gcc-config -c ${CTARGET} 2>&1) || return 0

	# if the previously selected config has the same major.minor (branch) as
	# the version we are installing, then it will probably be uninstalled
	# for being in the same SLOT, make sure we run gcc-config.
	local curr_config_ver=$(env -i ROOT="${ROOT}" gcc-config -S ${curr_config} | awk '{print $2}')

	local curr_branch_ver=$(get_version_component_range 1-2 ${curr_config_ver})

	# If we're using multislot, just run gcc-config if we're installing
	# to the same profile as the current one.
	use multislot && return $([[ ${curr_config_ver} == ${GCC_CONFIG_VER} ]])

	if [[ ${curr_branch_ver} == ${GCC_BRANCH_VER} ]] ; then
		return 0
	else
		# if we're installing a genuinely different compiler version,
		# we should probably tell the user -how- to switch to the new
		# gcc version, since we're not going to do it for him/her.
		# We don't want to switch from say gcc-3.3 to gcc-3.4 right in
		# the middle of an emerge operation (like an 'emerge -e world'
		# which could install multiple gcc versions).
		einfo "The current gcc config appears valid, so it will not be"
		einfo "automatically switched for you.	If you would like to"
		einfo "switch to the newly installed gcc version, do the"
		einfo "following:"
		echo
		einfo "gcc-config ${CTARGET}-${GCC_CONFIG_VER}"
		einfo "source /etc/profile"
		echo
		ebeep
		return 1
	fi
}

do_gcc_config() {
	if ! should_we_gcc_config ; then
		env -i ROOT="${ROOT}" gcc-config --use-old --force
		return 0
	fi

	local current_gcc_config="" current_specs="" use_specs=""

	# We grep out any possible errors
	current_gcc_config=$(env -i ROOT="${ROOT}" gcc-config -c ${CTARGET} | grep -v '^ ')
	if [[ -n ${current_gcc_config} ]] ; then
		# figure out which specs-specific config is active
		current_specs=$(gcc-config -S ${current_gcc_config} | awk '{print $3}')
		[[ -n ${current_specs} ]] && use_specs=-${current_specs}
	fi
	if [[ -n ${use_specs} ]] && \
	   [[ ! -e ${ROOT}/etc/env.d/gcc/${CTARGET}-${GCC_CONFIG_VER}${use_specs} ]]
	then
		ewarn "The currently selected specs-specific gcc config,"
		ewarn "${current_specs}, doesn't exist anymore. This is usually"
		ewarn "due to enabling/disabling hardened or switching to a version"
		ewarn "of gcc that doesnt create multiple specs files. The default"
		ewarn "config will be used, and the previous preference forgotten."
		ebeep
		epause
		use_specs=""
	fi

	gcc-config ${CTARGET}-${GCC_CONFIG_VER}${use_specs}
}

# This function allows us to gentoo-ize gcc's version number and bugzilla
# URL without needing to use patches.
gcc_version_patch() {
	# gcc-4.3+ has configure flags (whoo!)
	tc_version_is_at_least 4.3 && einfo "Building ${version_string} (${BRANDING_GCC_PKGVERSION})" && return 0
	
	local version_string=${GCC_CONFIG_VER}
	[[ -n ${BRANCH_UPDATE} ]] && version_string="${version_string} ${BRANCH_UPDATE}"

	einfo "patching gcc version: ${version_string} (${BRANDING_GCC_PKGVERSION})"

	if grep -qs VERSUFFIX "${S}"/gcc/version.c ; then
		sed -i -e "s~VERSUFFIX \"\"~VERSUFFIX \" (${BRANDING_GCC_PKGVERSION})\"~" \
			"${S}"/gcc/version.c || die "failed to update VERSUFFIX with Gentoo branding"
	else
		version_string="${version_string} (${BRANDING_GCC_PKGVERSION})"
		sed -i -e "s~\(const char version_string\[\] = \"\).*\(\".*\)~\1$version_string\2~" \
			"${S}"/gcc/version.c || die "failed to update version.c with Gentoo branding."
	fi
	sed -i -e 's~gcc\.gnu\.org\/bugs\.html~bugs\.gentoo\.org\/~' \
		"${S}"/gcc/version.c || die "Failed to change the bug URL"
}	

# The purpose of this DISGUSTING gcc multilib hack is to allow 64bit libs
# to live in lib instead of lib64 where they belong, with 32bit libraries
# in lib32. This hack has been around since the beginning of the amd64 port,
# and we're only now starting to fix everything that's broken. Eventually
# this should go away.
#
# Travis Tilley <lv@gentoo.org> (03 Sep 2004)
#
disgusting_gcc_multilib_HACK() {
	local config
	local libdirs
	if has_multilib_profile ; then
		case $(tc-arch) in
			amd64)
				config="i386/t-linux64"
				libdirs="../$(get_abi_LIBDIR amd64) ../$(get_abi_LIBDIR x86)" \
			;;
			ppc64)
				config="rs6000/t-linux64"
				libdirs="../$(get_abi_LIBDIR ppc64) ../$(get_abi_LIBDIR ppc)" \
			;;
		esac
	else
		die "Your profile is no longer supported by portage."
	fi

	einfo "updating multilib directories to be: ${libdirs}"
	sed -i -e "s:^MULTILIB_OSDIRNAMES.*:MULTILIB_OSDIRNAMES = ${libdirs}:" "${S}"/gcc/config/${config}
}

disable_multilib_libjava() {
	if is_gcj ; then
		# We dont want a multilib libjava, so lets use this hack taken from fedora
		pushd "${S}" > /dev/null
		sed -i -e 's/^all: all-redirect/ifeq (\$(MULTISUBDIR),)\nall: all-redirect\nelse\nall:\n\techo Multilib libjava build disabled\nendif/' libjava/Makefile.in
		sed -i -e 's/^install: install-redirect/ifeq (\$(MULTISUBDIR),)\ninstall: install-redirect\nelse\ninstall:\n\techo Multilib libjava install disabled\nendif/' libjava/Makefile.in
		sed -i -e 's/^check: check-redirect/ifeq (\$(MULTISUBDIR),)\ncheck: check-redirect\nelse\ncheck:\n\techo Multilib libjava check disabled\nendif/' libjava/Makefile.in
		sed -i -e 's/^all: all-recursive/ifeq (\$(MULTISUBDIR),)\nall: all-recursive\nelse\nall:\n\techo Multilib libjava build disabled\nendif/' libjava/Makefile.in
		sed -i -e 's/^install: install-recursive/ifeq (\$(MULTISUBDIR),)\ninstall: install-recursive\nelse\ninstall:\n\techo Multilib libjava install disabled\nendif/' libjava/Makefile.in
		sed -i -e 's/^check: check-recursive/ifeq (\$(MULTISUBDIR),)\ncheck: check-recursive\nelse\ncheck:\n\techo Multilib libjava check disabled\nendif/' libjava/Makefile.in
		popd > /dev/null
	fi
}

# make sure the libtool archives have libdir set to where they actually
# -are-, and not where they -used- to be.  also, any dependencies we have
# on our own .la files need to be updated.
fix_libtool_libdir_paths() {
	pushd "${D}" >/dev/null
	local dir=${LIBPATH}
	local allarchives=$(cd ./${dir}; echo *.la)
	allarchives="\(${allarchives// /\\|}\)"
	sed -i \
		-e "/^libdir=/s:=.*:='${dir}':" \
		./${dir}/*.la
 	sed -i \
 		-e "/^dependency_libs=/s:/[^ ]*/${allarchives}:${LIBPATH}/\1:g" \
		$(find ./${PREFIX}/lib* -maxdepth 3 -name '*.la') \
		./${dir}/*.la
	popd >/dev/null
}

is_multilib() {
	[[ ${GCCMAJOR} < 3 ]] && return 1
	case ${CTARGET} in
		mips64*|powerpc64*|s390x*|sparc*|x86_64*)
			has_multilib_profile || use multilib ;;
		*)	false ;;
	esac
}

is_cxx() {
	gcc-lang-supported 'c++' || return 1
	! use nocxx
}

is_d() {
	gcc-lang-supported d || return 1
	use d
}

is_f77() {
	gcc-lang-supported f77 || return 1
	use fortran
}

is_f95() {
	gcc-lang-supported f95 || return 1
	use fortran
}

is_fortran() {
	gcc-lang-supported fortran || return 1
	use fortran
}

is_gcj() {
	gcc-lang-supported java || return 1
	use gcj
}

is_libffi() {
	has libffi ${IUSE} || return 1
	use libffi
}

is_objc() {
	gcc-lang-supported objc || return 1
	use objc
}

is_objcxx() {
	gcc-lang-supported 'obj-c++' || return 1
	use objc++
}

is_ada() {
	gcc-lang-supported ada || return 1
	use ada
}

is_treelang() {
	is_crosscompile && return 1 #199924
	gcc-lang-supported treelang || return 1
	#use treelang
	return 0
}
