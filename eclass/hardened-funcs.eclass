

# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/hardened-funcs.eclass,v 1.0 2008/12/22 09:20:34 zorry Exp $
#
# Maintainer: Hardened Ninjas <hardened@gentoo.org>

inherit eutils toolchain-funcs
___ECLASS_RECUR_HARDENED_FUNCS="yes"
[[ -z ${___ECLASS_RECUR_FLAG_O_MATIC} ]] && inherit flag-o-matic

# Stuff for flag-o-matic.eclass
# Return true if the HFILTER_CONTROL permits the requested filter
# _hfilter_allowed <category/pf> <pie|ssp|relro|now|fortify|strict>
_hfilter_allowed() {
	[[ -z ${HFILTER_CONTROL} ]] && return 0
	[[ $(awk -v CPF="$1" -v TYPE="$2" 'BEGIN { ok=0 }
$1=="allow" && CPF~$2 && TYPE==$3 { ok=0 }
$1=="deny" && CPF~$2 && TYPE==$3 { ok=1 }
END { print ok }' ${HFILTER_CONTROL}) == 0 ]]
}

# Internal function for _filter-hardened
# _manage_hardened <flag being filtered> <minispec to use> <cflag to use>
_manage-hardened() {
	local filter=$1 newspec=$2
	[[ -z $3 ]] && die "Internal hardened-funcs error ($*) - please report"

	if ! $(_hfilter_allowed ${CATEGORY}/${PF} ${newspec/no}); then
		ewarn "Hardened compiler filter $1 requested by ebuild - ignored by request in ${HFILTER_CONTROL}"
		return 0
	fi

	if _gcc-specs-exists ${newspec}.specs; then
		[[ ${GCC_SPECS} == *${newspec}* ]] && return 0
		[[ -z ${GCC_SPECS} ]] || newspec=":${newspec}"
		export GCC_SPECS="${GCC_SPECS}${newspec}.specs"
		elog "Hardened compiler filtered $1 - GCC_SPECS set to ${GCC_SPECS}"
	else
		local oldspec=${GCC_SPECS/*\/} newspec=""
		case $2 in
			"nopie")
				case ${oldspec} in
					"" | "hardened.specs")
						newspec="hardenednopie.specs";;
					"hardenednossp.specs")
						newspec="hardenednopiessp.specs";;
				esac
				;;
			"nossp" | "nosspall")
				case ${oldspec} in
					"" | "hardened.specs")
						newspec="hardenednossp.specs";;
					"hardenednopie.specs")
						newspec="hardenednopiessp.specs";;
				esac
				;;
			"noznow")
				newspec="vanilla.specs";;
			*)
				die "Internal hardened-funcs.eclass error - unrecognised hardened filter $2"
				;;
		esac
		if [[ -n ${newspec} ]]; then
			if _gcc-specs-exists ${newspec}; then
				export GCC_SPECS="${newspec}"
				elog "Hardened compiler filtered $1 - GCC_SPECS set to ${GCC_SPECS}"
			else
				# This can happen if the compiler is not built with split-specs
				#die "Internal hardend-funcs error ($*) - please report"
				ewarn "Hardened compiler filter $1 requested by ebuild - ignored since neither $2 nor ${newspec} exist"
			fi
		else
			_raw_append_flag $3
			elog "Hardened compiler filtered $1 - CFLAGS set to ${CFLAGS}"
		fi
	fi
}

# inverted filters for hardened compiler.  This is trying to unpick
# the hardened compiler defaults.
_filter-hardened() {
	local f
	for f in "$@" ; do
		case "${f}" in
			# Ideally we should only concern ourselves with PIE flags,
			# not -fPIC or -fpic, but too many places filter -fPIC without
			# thinking about -fPIE.
			-fPIC|-fpic|-fPIE|-fpie|-Wl,pie|-pie)
				gcc-specs-pie &&
					_manage-hardened ${f} nopie -nopie ;;
			-fstack-protector)
				gcc-specs-ssp &&
					_manage-hardened ${f} nossp -fno-stack-protector ;;
			-fstack-protector-all)
				gcc-specs-ssp-to-all &&
					_manage-hardened ${f} nosspall -fno-stack-protector-all ;;
			-now|-Wl,-z,now)
				gcc-specs-now &&
					_manage-hardened ${f} noznow -nonow ;;
			-D_FORTIFY_SOURCE=2|-D_FORTIFY_SOURCE=1|-D_FORTIFY_SOURCE=0)
				gcc-specs-fortify &&
				_manage-hardened ${f} nofortify -U_FORTIFY_SOURCE ;;
			-fno-strict-overflow)
				gcc-specs-strict-overflow &&
					_manage-hardened ${f} strict -fstrict-overflow ;;
		esac
	done
}
# Special case: -fno-stack-protector-all needs special management
# on hardened gcc-4.
_append-flag() {
	[[ -z "$1" ]] && return 0
	case "$1" in
	-fno-stack-protector-all)
	    gcc-specs-ssp-to-all || continue
		_manage-hardened -fstack-protector-all nosspall "$1" ;;
	*)
	_raw_append_flag "$1"
	esac
}
# stuff for toolchain.eclass
get_gcc_src_uri_hardened() {
#	PIE_VER
#	PIE_GCC_VER
#	obsoleted: PIE_CORE
#			These variables control patching in various updates for the logic
#			controlling Position Independant Executables. PIE_VER is expected
#			to be the version of this patch, PIE_GCC_VER the gcc version of
#			the patch, and PIE_CORE (obsoleted) the actual filename of the patch.
#			An example:
#					PIE_VER="8.7.6.5"
#					PIE_GCC_VER="3.4.0"
#			The resulting filename of this tarball will be:
#			gcc-${PIE_GCC_VER:-${GCC_RELEASE_VER}}-piepatches-v${PIE_VER}.tar.bz2
#				old syntax (do not define PIE_CORE anymore):
#					PIE_CORE="gcc-3.4.0-piepatches-v${PIE_VER}.tar.bz2"
#
#	SPECS_VER
#	SPECS_GCC_VER
#			This is for the minispecs files hardened gcc 4
#
#	PP_VER
#	PP_GCC_VER
#	obsoleted: PP_FVER
#			These variables control patching in stack smashing protection
#			support. They both control the version of ProPolice to download.
#
#		PP_VER / PP_GCC_VER
#			Used to roll our own custom tarballs of ssp.
#		PP_FVER / PP_VER
#			Used for mirroring ssp straight from IBM.
#			PP_VER sets the version of the directory in which to find the
#			patch, and PP_FVER sets the version of the patch itself. For
#			example:
#					PP_VER="3_4"
#					PP_FVER="${PP_VER//_/.}-2"
#			would download gcc3_4/protector-3.4-2.tar.gz

	export PIE_GCC_VER=${PIE_GCC_VER:-${GCC_RELEASE_VER}}
	export PP_GCC_VER=${PP_GCC_VER:-${GCC_RELEASE_VER}}
	export SPECS_GCC_VER=${SPECS_GCC_VER:-${GCC_RELEASE_VER}}
	
	[[ -n ${PIE_VER} ]] && \
		PIE_CORE=${PIE_CORE:-gcc-${PIE_GCC_VER}-piepatches-v${PIE_VER}.tar.bz2}
	
	# propolice aka stack smashing protection
	if [[ -n ${PP_VER} ]] ; then
		if [[ -n ${PP_FVER} ]] ; then
			GCC_SRC_URI="${GCC_SRC_URI}
				!nossp? (
					http://www.research.ibm.com/trl/projects/security/ssp/gcc${PP_VER}/protector-${PP_FVER}.tar.gz
					$(gentoo_urls protector-${PP_FVER}.tar.gz)
				)"
		else
			GCC_SRC_URI="${GCC_SRC_URI} $(gentoo_urls gcc-${PP_GCC_VER}-ssp-${PP_VER}.tar.bz2)"
		fi
	fi
	
	# strawberry pie, Cappuccino and a Gauloises (it's a good thing)
	[[ -n ${PIE_VER} ]] && \
		GCC_SRC_URI="${GCC_SRC_URI} !nopie? ( $(gentoo_urls ${PIE_CORE})
			http://weaver.gentooenterprise.com/hardened/patches/gcc-${PIE_GCC_VER}-piepatches-v${PIE_VER}.tar.bz2
		)"
	# gcc minispec for the hardened gcc 4 compiler
        [[ -n ${SPECS_VER} ]] && \
                GCC_SRC_URI="${GCC_SRC_URI} !nopie? ( $(gentoo_urls gcc-${SPECS_GCC_VER}-default-specs-${SPECS_VER}.tar.bz2)
			http://weaver.gentooenterprise.com/hardened/patches/gcc-${SPECS_GCC_VER}-default-specs-${SPECS_VER}.tar.bz2
		)"
}
# The gentoo piessp patches allow for 4 configurations:
# 1) PIE+SSP by default
# 2) PIE by default
# 3) SSP by default
# 4) PIE+SSP+FORTIFY by default on gcc 4
hardened_gcc_works() {
	if [[ $1 == "pie" ]] ; then
		# $gcc_cv_ld_pie is unreliable as it simply take the output of
		# `ld --help | grep -- -pie`, that reports the option in all cases, also if
		# the loader doesn't actually load the resulting executables.
		# To avoid breakage, blacklist FreeBSD here at least
		[[ ${CTARGET} == *-freebsd* ]] && return 1

		want_pie || return 1
		hardened_gcc_is_stable pie && return 0
		if  tc_version_is_at_least 4.3.2 ; then
			ewarn "PIE is not supported on this arch $(tc-arch)"	
		else
			if has ~$(tc-arch) ${ACCEPT_KEYWORDS} ; then
				hardened_gcc_check_unsupported pie && return 1
				ewarn "Allowing pie-by-default for an unstable arch ($(tc-arch))"
				return 0
			fi
		fi
		return 1
	elif [[ $1 == "ssp" ]] ; then
		want_ssp || return 1
		hardened_gcc_is_stable ssp && return 0
		if tc_version_is_at_least 4.3.2 ; then
			ewarn "SSP is not supported on this arch $(tc-arch)" 
			return 1	
		else
			if has ~$(tc-arch) ${ACCEPT_KEYWORDS} ; then
				hardened_gcc_check_unsupported ssp && return 1
				ewarn "Allowing ssp-by-default for an unstable arch ($(tc-arch))"
				return 0
			fi
		fi
		return 1
	elif [[ $1 == "fortify" ]] ; then
		want_fortify || return 1
		hardened_gcc_is_stable fortify && return 0
		ewarn "Fortify is not supported on this $(tc-arch)" 
		return 1
	else
		# laziness ;)
		hardened_gcc_works pie || return 1
		hardened_gcc_works ssp || return 1
		# This is needed for not to mess with gcc 3 and SSP
		if tc_version_is_at_least 4.3.2 ; then
			hardened_gcc_works fortify || return 1
		fi
		return 0
	fi
}

hardened_gcc_is_stable() {
if tc_version_is_at_least 4.3.2 ; then
# For the new hardened setup in gcc 4.3 ebuild
	if [[ $1 == "pie" ]] ; then
		if [[ ${CTARGET} == *-uclibc* ]] && has ~$(tc-arch) ${PIE_UCLIBC_STABLE} || has ~$(tc-arch) ${PIE_GLIBC_STABLE} ; then
			ewarn "Allowing pie-by-default for an untested arch $(tc-arch)" && return 0
		elif [[ ${CTARGET} == *-uclibc* ]] && has $(tc-arch) ${PIE_UCLIBC_STABLE} || has $(tc-arch) ${PIE_GLIBC_STABLE} ; then
			return 0
		else
			return 1
		fi
	elif [[ $1 == "ssp" ]] ; then
		if [[ ${CTARGET} == *-uclibc* ]] && has ~$(tc-arch) ${SSP_UCLIBC_STABLE} || has ~$(tc-arch) ${SSP_STABLE} ; then
			ewarn "Allowing ssp-by-default for an untested arch $(tc-arch)" && return 0
	elif [[ ${CTARGET} == *-uclibc* ]] && has $(tc-arch) ${SSP_UCLIBC_STABLE} || has $(tc-arch) ${SSP_STABLE} ; then
			return 0
		else
			return 1
		fi
	elif [[ $1 == "fortify" ]] ; then
		if [[ ${CTARGET} == *-uclibc* ]] && has ~$(tc-arch) ${FORTIFY_UCLIBC_STABLE} || has ~$(tc-arch) ${FORTIFY_STABLE} ; then
			ewarn "Allowing fortify-by-default for an untested arch $(tc-arch)" && return 0
		elif [[ ${CTARGET} == *-uclibc* ]] && has $(tc-arch) ${FORTIFY_UCLIBC_STABLE} || has $(tc-arch) ${FORTIFY_STABLE} ; then
			return 0
		else
			return 1
		fi
	else
		die "hardened_gcc_stable needs to be called with pie, ssp or fortify"
	fi
# For the old hardened gcc 3.4 ebuild
else
	if [[ $1 == "pie" ]] ; then
		# HARDENED_* variables are deprecated and here for compatibility
		local tocheck="${HARDENED_PIE_WORKS} ${HARDENED_GCC_WORKS}"
		if [[ ${CTARGET} == *-uclibc* ]] ; then
			tocheck="${tocheck} ${PIE_UCLIBC_STABLE}"
		else
			tocheck="${tocheck} ${PIE_GLIBC_STABLE}"
		fi
	elif [[ $1 == "ssp" ]] ; then
		# ditto
		local tocheck="${HARDENED_SSP_WORKS} ${HARDENED_GCC_WORKS}"
		if [[ ${CTARGET} == *-uclibc* ]] ; then
			tocheck="${tocheck} ${SSP_UCLIBC_STABLE}"
		else
			tocheck="${tocheck} ${SSP_STABLE}"
		fi
	else
		die "hardened_gcc_stable needs to be called with pie or ssp"
	fi
	hasq $(tc-arch) ${tocheck} && return 0
fi
	return 1
}
# For the old hardened gcc 3.4 ebuild
hardened_gcc_check_unsupported() {
	local tocheck=""
	# if a variable is unset, we assume that all archs are unsupported. since
	# this function is never called if hardened_gcc_is_stable returns true,
	# this shouldn't cause problems... however, allowing this logic to work
	# even with the variables unset will break older ebuilds that dont use them.
	if [[ $1 == "pie" ]] ; then
		if [[ ${CTARGET} == *-uclibc* ]] ; then
			[[ -z ${PIE_UCLIBC_UNSUPPORTED} ]] && return 0
			tocheck="${tocheck} ${PIE_UCLIBC_UNSUPPORTED}"
		else
			[[ -z ${PIE_GLIBC_UNSUPPORTED} ]] && return 0
			tocheck="${tocheck} ${PIE_GLIBC_UNSUPPORTED}"
		fi
	elif [[ $1 == "ssp" ]] ; then
		if [[ ${CTARGET} == *-uclibc* ]] ; then
			[[ -z ${SSP_UCLIBC_UNSUPPORTED} ]] && return 0
			tocheck="${tocheck} ${SSP_UCLIBC_UNSUPPORTED}"
		else
			[[ -z ${SSP_UNSUPPORTED} ]] && return 0
			tocheck="${tocheck} ${SSP_UNSUPPORTED}"
		fi
	else
		die "hardened_gcc_check_unsupported needs to be called with pie or ssp"
	fi

	hasq $(tc-arch) ${tocheck} && return 0
	return 1
}
check_hardened_compiler_vanilla() {
	# This situation is when we trying to build a non-hardened compiler with a 
	# hardened compiler. 
	if gcc-specs-pie || gcc-specs-ssp || gcc-specs-fortify && ! use hardened ; then
		eerror "You have requested a non-hardened compiler, but you are using a hardened" 
		eerror "compiler to do so, which is inadvisable.  If you really want to build a" 
		eerror "non-hardened compiler, switch to the vanilla compiler with gcc-config" 
		eerror "first." 
		die "You must build non-hardened compilers with vanilla-spec compilers." 
	fi
}
has_libssp() {
	[[ -e /$(get_libdir)/libssp.so ]] && return 0
	return 1
}

want_libssp() {
	[[ ${GCC_LIBSSP_SUPPORT} == "true" ]] || return 1
	has_libssp || return 1
	[[ -n ${PP_VER} ]] || return 1
	return 0
}
gcc_has_native_ssp() {
	[[ ${GCCMAJOR} -lt 4 ]] && return 1
        # gcc 4.1 and above have native ssp support but we have started with 4.3.2 for hardened
        tc_version_is_at_least 4.3.2 && [[ -z ${PP_VER} ]] && return 0
        return 1
}
_want_stuff() {
	local var=$1 flag=$2
	[[ -z ${!var} ]] && return 1
	use ${flag} && return 0
	return 1
}
if tc_version_is_at_least 4.3.2 ; then
	# We don't use SPLIT_SPECS and it only will applay to USE=hardened
	# so we don't mess with default and vanilla
	want_ssp() { use hardened && [[ -n ${SPECS_VER} ]] && gcc_has_native_ssp || _want_stuff PP_VER !nossp ; }
else
	# For hardened gcc 3.4
	want_ssp() { _want_stuff PP_VER !nossp ; }
fi
want_pie() { _want_stuff PIE_VER !nopie ; }
want_boundschecking() { _want_stuff HTB_VER boundschecking ; }
want_split_specs() { [[ ${SPLIT_SPECS} == "true" ]] && want_pie ; }
# Only supported on hardened gcc 4.3 and newer
want_fortify() { use hardened && libc_has_fortify && tc_version_is_at_least 4.2 && [[ -n ${SPECS_VER} ]] ; }
want_minispecs() { 
	if tc_version_is_at_least 4.3.2 && use hardened ; then
		if [[ -n ${SPECS_VER} ]] ; then
			return 0 
		else
			die "For Hardend to work you need the minispecs files"
		fi
	fi
	return 1	
}
	

# This function checks whether or not glibc has the support required to build
# Position Independant Executables with gcc.
glibc_have_pie() {
	if [[ ! -f ${ROOT}/usr/$(get_libdir)/Scrt1.o ]] ; then
		echo
		ewarn "Your glibc does not have support for pie, the file Scrt1.o is missing"
		ewarn "Please update your glibc to a proper version or disable hardened"
		echo
		return 1
	fi
}
# This function determines whether or not libc has been patched with stack
# smashing protection support.
libc_has_ssp() {
	[[ ${ROOT} != "/" ]] && return 0

	# lib hacks taken from sandbox configure
	echo 'int main(){}' > "${T}"/libctest.c
	LC_ALL=C gcc "${T}"/libctest.c -lc -o libctest -Wl,-verbose &> "${T}"/libctest.log || return 1
	local libc_file=$(awk '/attempt to open/ { if (($4 ~ /\/libc\.so/) && ($5 == "succeeded")) LIBC = $4; }; END {print LIBC}' "${T}"/libctest.log)

	[[ -z ${libc_file} ]] && die "Unable to find a libc !?"

	# Check for gcc-4.x style ssp support
	if	[[ -n $(readelf -s "${libc_file}" 2>/dev/null | \
				grep 'FUNC.*GLOBAL.*__stack_chk_fail') ]]
	then
		return 0
	else
		# Check for gcc-3.x style ssp support
		if	[[ -n $(readelf -s "${libc_file}" 2>/dev/null | \
					grep 'OBJECT.*GLOBAL.*__guard') ]] && \
			[[ -n $(readelf -s "${libc_file}" 2>/dev/null | \
					grep 'FUNC.*GLOBAL.*__stack_smash_handler') ]]
		then
			return 0
		elif is_crosscompile ; then
			die "'${libc_file}' was detected w/out ssp, that sucks (a lot)"
		else
			return 1
		fi
	fi
}
# My need to redo this lib check later.
# <zorry[@]ume.nu
libc_has_fortify() {
	[[ ${ROOT} != "/" ]] && return 0

	# lib hacks taken from sandbox configure
	echo 'int main(){}' > "${T}"/libctest.c
	LC_ALL=C gcc "${T}"/libctest.c -lc -o libctest -Wl,-verbose &> "${T}"/libctest.log || return 1
	local libc_file=$(awk '/attempt to open/ { if (($4 ~ /\/libc\.so/) && ($5 == "succeeded")) LIBC = $4; }; END {print LIBC}' "${T}"/libctest.log)

	[[ -z ${libc_file} ]] && die "Unable to find a libc !?"

	# Check for gcc-4.x style fortify  support
	if	[[ -n $(readelf -s "${libc_file}" 2>/dev/null | \
				grep 'FUNC.*GLOBAL.*__fortify_fail') ]]
	then
		return 0
	fi
}
# Defaults to enable for all hardened toolchains <gcc 4
	gcc_common_hard="-DEFAULT_RELRO -DEFAULT_BIND_NOW"
# Configure to build with the hardened GCC 3 specs as the default
# Don't need it if we have minispec like gcc 4
make_gcc_hard() {
	if hardened_gcc_works ; then
		einfo "Updating gcc to use automatic PIE + SSP building ..."
		sed -e "s|^HARD_CFLAGS = |HARD_CFLAGS = -DEFAULT_PIE_SSP ${gcc_common_hard} |" \
			-i "${S}"/gcc/Makefile.in || die "Failed to update gcc!"
	elif hardened_gcc_works pie ; then
		einfo "Updating gcc to use automatic PIE building ..."
		ewarn "SSP has not been enabled by default"
		sed -e "s|^HARD_CFLAGS = |HARD_CFLAGS = -DEFAULT_PIE ${gcc_common_hard} |" \
			-i "${S}"/gcc/Makefile.in || die "Failed to update gcc!"
	elif hardened_gcc_works ssp ; then
		einfo "Updating gcc to use automatic SSP building ..."
		ewarn "PIE has not been enabled by default"
		sed -e "s|^HARD_CFLAGS = |HARD_CFLAGS = -DEFAULT_SSP ${gcc_common_hard} |" \
			-i "${S}"/gcc/Makefile.in || die "Failed to update gcc!"
	else
		# do nothing if hardened isnt supported, but dont die either
		ewarn "hardened is not supported for this arch in this gcc version"
		ebeep
		return 0
	fi
}

# now we generate different spec files so that the user can select a compiler
# that enforces certain features in gcc itself and so we don't have to worry
# about a certain package ignoring CFLAGS/LDFLAGS
# Not needed if we use minispecs
_create_specs_file() {
	# Usage: _create_specs_file <USE flag> <specs name> <CFLAGS>
	local uflag=$1 name=$2 flags=${*:3}
	ebegin "Creating a ${name} gcc specs file"
	pushd "${WORKDIR}"/build/gcc > /dev/null
	if [[ -z ${uflag} ]] || use ${uflag} ; then
		# backup the compiler first
		cp Makefile Makefile.orig
		sed -i -e '/^HARD_CFLAGS/s:=.*:='"${flags}"':' Makefile
		mv xgcc xgcc.foo
		mv gcc.o gcc.o.foo
		emake -s xgcc
		$(XGCC) -dumpspecs > "${WORKDIR}"/build/${name}.specs
		# restore everything to normal
		mv gcc.o.foo gcc.o
		mv xgcc.foo xgcc
		mv Makefile.orig Makefile
	else
		$(XGCC) -dumpspecs > "${WORKDIR}"/build/${name}.specs
	fi
	popd > /dev/null
	eend $([[ -s ${WORKDIR}/build/${name}.specs ]] ; echo $?)
}
create_vanilla_specs_file()			 { _create_specs_file hardened vanilla ; }
create_hardened_specs_file()		 { _create_specs_file !hardened hardened  ${gcc_common_hard} -DEFAULT_PIE_SSP ; }
create_hardenednossp_specs_file()	 { _create_specs_file "" hardenednossp	  ${gcc_common_hard} -DEFAULT_PIE ; }
create_hardenednopie_specs_file()	 { _create_specs_file "" hardenednopie	  ${gcc_common_hard} -DEFAULT_SSP ; }
create_hardenednopiessp_specs_file() { _create_specs_file "" hardenednopiessp ${gcc_common_hard} ; }

split_out_specs_files() {
	local s spec_list="hardenednopiessp vanilla"
	if hardened_gcc_works ; then
		spec_list="${spec_list} hardened hardenednossp hardenednopie"
	elif hardened_gcc_works pie ; then
		spec_list="${spec_list} hardenednossp"
	elif hardened_gcc_works ssp ; then
		spec_list="${spec_list} hardenednopie"
	fi
	for s in ${spec_list} ; do
		create_${s}_specs_file || return 1
	done
}
hardened_compiler_src_unpack_setup() {
	# Fail if using pie patches, building hardened, and glibc doesnt have
	# the necessary support
	want_pie && use hardened && glibc_have_pie

	want_pie && use hardened && BRANDING_GCC_PKGVERSION=${BRANDING_GCC_PKGVERSION/Gentoo/Gentoo Hardened}
	# For the old gcc < 3.4
	if use hardened && ! want_minispecs ; then
		einfo "updating configuration to build hardened GCC gcc-3 style"
		make_gcc_hard || die "failed to make gcc hard"
	fi
}
setup_minispecs_gcc_build_specs() {
	# Setup the "specs" file for gcc to use when building.
	if use hardened && want_minispecs ; then
		if hardened_gcc_works pie ; then
        		cat "${WORKDIR}"/specs/pie.specs >> "${WORKDIR}"/build.specs
		fi
		if hardened_gcc_works ssp ; then
			for s in ssp sspall; do
				cat "${WORKDIR}"/specs/${s}.specs >> "${WORKDIR}"/build.specs
			done
		fi
		if hardened_gcc_works fortify ; then
			cat "${WORKDIR}"/specs/fortify.specs >> "${WORKDIR}"/build.specs
		fi
		for s in nostrict znow ; do
			cat "${WORKDIR}"/specs/${s}.specs >> "${WORKDIR}"/build.specs
		done
		export GCC_SPECS="${WORKDIR}"/build.specs
	fi
}
setup_split_specs() {
	# Do not create multiple specs files for PIE+SSP if boundschecking is in
	# USE, as we disable PIE+SSP when it is.
	# minispecs wil not need to split out specs.
	if [[ ${ETYPE} == "gcc-compiler" ]] && want_split_specs && ! want_minispecs; then
		split_out_specs_files || die "failed to split out specs"
	fi
}
copy_minispecs_gcc_specs() {
	# Build system specs file which, if it exists, must be a complete set of
	# specs as it completely and unconditionally overrides the builtin specs.
	# For gcc 4
	if use hardened && want_minispecs ; then
		$(XGCC) -dumpspecs > "${WORKDIR}"/specs/specs
		cat "${WORKDIR}"/build.specs >> "${WORKDIR}"/specs/specs
		insinto ${LIBPATH}
		doins "${WORKDIR}"/specs/* || die "failed to install specs"
        fi
}
create_hardened_gcc_env_entry() {
	# For the old gcc 3 and split_specs
	if want_split_specs ; then
		if use hardened ; then
			create_gcc_env_entry vanilla
		fi
		! use hardened && hardened_gcc_works && create_gcc_env_entry hardened
		if hardened_gcc_works || hardened_gcc_works pie ; then
			create_gcc_env_entry hardenednossp
		fi
		if hardened_gcc_works || hardened_gcc_works ssp ; then
			create_gcc_env_entry hardenednopie
		fi
		create_gcc_env_entry hardenednopiessp

		insinto ${LIBPATH}
		doins "${WORKDIR}"/build/*.specs || die "failed to install specs"
		
	fi
	# Setup the gcc_env_entry for hardened gcc 4 with minispecs
	if want_minispecs ; then
		if hardened_gcc_works pie ; then
		    create_gcc_env_entry nopie
		fi
		if hardened_gcc_works ssp ; then
		    create_gcc_env_entry nossp_all
		fi
		if hardened_gcc_works fortify ; then
		    create_gcc_env_entry nofortify
		fi
		create_gcc_env_entry vanilla
	fi
}
hardened_gcc_quick_unpack() {
	export PIE_GCC_VER=${PIE_GCC_VER:-${GCC_RELEASE_VER}}
	export PP_GCC_VER=${PP_GCC_VER:-${GCC_RELEASE_VER}}
	export SPECS_GCC_VER=${SPECS_GCC_VER:-${GCC_RELEASE_VER}}
	if want_ssp ; then
		if [[ -n ${PP_FVER} ]] ; then
			# The gcc 3.4 propolice versions are meant to be unpacked to ${S}
			pushd "${S}" > /dev/null
			unpack protector-${PP_FVER}.tar.gz
			popd > /dev/null
		fi
		if [[ -n ${PP_VER} ]] ; then
			unpack gcc-${PP_GCC_VER}-ssp-${PP_VER}.tar.bz2
		fi
		# GCC 4.1 have built in SSP so need to have patch
		if gcc_has_native_ssp && use hardened && hardened_gcc_works ssp ; then
			    einfo "No need for ssp patch for using the built in ssp"
		fi
	fi

	if want_pie ; then
		if [[ -n ${PIE_CORE} ]] ; then
			unpack ${PIE_CORE}
		else
			unpack gcc-${PIE_GCC_VER}-piepatches-v${PIE_VER}.tar.bz2
		fi
		[[ -n ${SPECS_VER} ]] && \
			unpack gcc-${SPECS_GCC_VER}-default-specs-${SPECS_VER}.tar.bz2
	fi
}
# Try to apply some stub patches so that gcc won't error out when
# passed parameters like -fstack-protector but no ssp is found
do_gcc_stub() {
	local v stub_patch=""
	for v in ${GCC_RELEASE_VER} ${GCC_BRANCH_VER} ; do
		stub_patch=${GCC_FILESDIR}/stubs/gcc-${v}-$1-stub.patch
		if [[ -e ${stub_patch} ]] && ! use vanilla ; then
			EPATCH_SINGLE_MSG="Applying stub patch for $1 ..." \
			epatch "${stub_patch}"
			return 0
		fi
	done
}
# patch in ProPolice Stack Smashing protection
do_gcc_SSP_patches() {
	# PARISC has no love ... it's our stack :(
	if [[ $(tc-arch) == "hppa" ]] || \
	   ! want_ssp || \
	   (want_boundschecking && [[ ${HTB_EXCLUSIVE} == "true" ]])
	then
		do_gcc_stub ssp
		return 0
	fi

	local ssppatch
	local sspdocs

	if [[ -n ${PP_FVER} ]] ; then
		# Etoh keeps changing where files are and what the patch is named
		if tc_version_is_at_least 3.4.1 ; then
			# >3.4.1 uses version in patch name, and also includes docs
			ssppatch="${S}/gcc_${PP_VER}.dif"
			sspdocs="yes"
		elif tc_version_is_at_least 3.4.0 ; then
			# >3.4 put files where they belong and 3_4 uses old patch name
			ssppatch="${S}/protector.dif"
			sspdocs="no"
		elif tc_version_is_at_least 3.2.3 ; then
			# earlier versions have no directory structure or docs
			mv "${S}"/protector.{c,h} "${S}"/gcc
			ssppatch="${S}/protector.dif"
			sspdocs="no"
		fi
	fi

	if [[ -n ${PP_VER} ]] ; then
		# Just start packaging the damn thing ourselves
		if [[ ${GCCMAJOR}.${GCCMINOR} < 4.0 ]] ; then
			mv "${WORKDIR}"/ssp/protector.{c,h} "${S}"/gcc/
		fi
		ssppatch=${WORKDIR}/ssp/gcc-${PP_GCC_VER}-ssp.patch
		# allow boundschecking and ssp to get along
		(want_boundschecking && [[ -e ${WORKDIR}/ssp/htb-ssp.patch ]]) \
		    && patch -s "${ssppatch}" "${WORKDIR}"/ssp/htb-ssp.patch
		fi

	if [[ -n ${ssppatch} ]] ; then
		epatch ${ssppatch}
	else
		! gcc_has_native_ssp && die "Sorry, SSP is not supported in this version"
	fi

	if [[ ${PN} == "gcc" && ${sspdocs} == "no" ]] ; then
		epatch "${GCC_FILESDIR}"/pro-police-docs.patch
	fi

	# Don't build crtbegin/end with ssp.
	# On gcc >=4.3 it is moved to the piepatch.
	if tc_version_is_at_least 3.4 && [[ ${GCCMAJOR}.${GCCMINOR} < 4.3 ]] ; then
		sed -e 's|^CRTSTUFF_CFLAGS = |CRTSTUFF_CFLAGS = -fno-stack-protector |' \
			-i gcc/Makefile.in || die "Failed to update crtstuff!"
	fi
	# if gcc in a stage3 defaults to ssp, is version 3.4.0 and a stage1 is built
	# the build fails building timevar.o w/:
	# cc1: stack smashing attack in function ix86_split_to_parts()
	# On gcc >=4.3 it is moved to the piepatch.
	if tc_version_is_at_least 3.4.0 && [[ ${GCCMAJOR}.${GCCMINOR} < 4.3 ]] ; then
		epatch "${GCC_FILESDIR}"/3.4.0/gcc-3.4.0-cc1-no-stack-protector.patch
	fi
	
	if hardened_gcc_works ssp && use hardened ; then
	    if gcc_has_native_ssp ; then
	    	BRANDING_GCC_PKGVERSION="${BRANDING_GCC_PKGVERSION}, builtin ssp"
	    else
		BRANDING_GCC_PKGVERSION="${BRANDING_GCC_PKGVERSION}, ssp-${PP_FVER:-${PP_GCC_VER}-${PP_VER}}"
	    fi
	fi
	
	# not needed for newer gcc 4
	if  [[ ${GCCMAJOR}.${GCCMINOR} < 4.3 ]] ; then
		if want_libssp ; then
			update_gcc_for_libssp
		else
			update_gcc_for_libc_ssp
		fi
	fi

	# Don't build libgcc with ssp.
	# On gcc >=4.3 it is moved to the piepatch
	if tc_version_is_at_least 3.4 && [[ ${GCCMAJOR}.${GCCMINOR} < 4.3 ]] ; then
		sed -e 's|^\(LIBGCC2_CFLAGS.*\)$|\1 -fno-stack-protector |' \
			-i gcc/Makefile.in || die "Failed to update gcc!"
	fi
}
# If glibc or uclibc has been patched to provide the necessary symbols itself,
# then lets use those for SSP instead of libgcc.
update_gcc_for_libc_ssp() {
	if libc_has_ssp ; then
		einfo "Updating gcc to use SSP from libc ..."
		sed -e 's|^\(LIBGCC2_CFLAGS.*\)$|\1 -D_LIBC_PROVIDES_SSP_|' \
			-i "${S}"/gcc/Makefile.in || die "Failed to update gcc!"
	fi
}
# a split out non-libc non-libgcc ssp requires additional spec logic changes
update_gcc_for_libssp() {
	einfo "Updating gcc to use SSP from libssp..."
	sed -e 's|^\(INTERNAL_CFLAGS.*\)$|\1 -D_LIBSSP_PROVIDES_SSP_|' \
		-i "${S}"/gcc/Makefile.in || die "Failed to update gcc!"
}
# do various updates to FORTIFY
do_gcc_FORTIFY_patches() {
	if hardened_gcc_works fortify && hardened_gcc_works ssp && gcc_has_native_ssp && use hardened ; then
	BRANDING_GCC_PKGVERSION="${BRANDING_GCC_PKGVERSION}, fortify"
	fi
	
	if hardened_gcc_works fortify && use hardened && ! gcc_has_native_ssp ; then
	BRANDING_GCC_PKGVERSION="${BRANDING_GCC_PKGVERSION}, builtin fortify"
	fi
}
# do various updates to PIE logic
do_gcc_PIE_patches() {
	if ! want_pie || \
	   (want_boundschecking && [[ ${HTB_EXCLUSIVE} == "true" ]])
	then
		return 0
	fi

	want_boundschecking \
		&& rm -f "${WORKDIR}"/piepatch/*/*-boundschecking-no.patch* \
		|| rm -f "${WORKDIR}"/piepatch/*/*-boundschecking-yes.patch*

	use vanilla && rm -f "${WORKDIR}"/piepatch/*/*uclibc*
	
	if tc_version_is_at_least 4.3.2 ; then
		guess_patch_type_in_dir "${WORKDIR}"/piepatch
                EPATCH_MULTI_MSG="Applying pie patches ..." \
                epatch "${WORKDIR}"/piepatch
        else
	
	guess_patch_type_in_dir "${WORKDIR}"/piepatch/upstream

	# corrects startfile/endfile selection and shared/static/pie flag usage
	EPATCH_MULTI_MSG="Applying upstream pie patches ..." \
	epatch "${WORKDIR}"/piepatch/upstream
	# adds non-default pie support (rs6000)
	EPATCH_MULTI_MSG="Applying non-default pie patches ..." \
	epatch "${WORKDIR}"/piepatch/nondef
	# adds default pie support (rs6000 too) if DEFAULT_PIE[_SSP] is defined
	EPATCH_MULTI_MSG="Applying default pie patches ..." \
	epatch "${WORKDIR}"/piepatch/def

	# we want to be able to control the pie patch logic via something other
	# than ALL_CFLAGS...
	# Don't need it if we have minispec like gcc 4
		sed -e '/^ALL_CFLAGS/iHARD_CFLAGS = ' \
		-e 's|^ALL_CFLAGS = |ALL_CFLAGS = $(HARD_CFLAGS) |' \
		-i "${S}"/gcc/Makefile.in
	fi

	BRANDING_GCC_PKGVERSION="${BRANDING_GCC_PKGVERSION}, pie-${PIE_VER}"
}
exclude_hardened_gcc_patches() {
#	PIEPATCH_EXCLUDE
#			List of filenames, relative to ${WORKDIR}/piepatch/
# Travis Tilley <lv@gentoo.org> (03 Sep 2004)
#
	for i in ${PIEPATCH_EXCLUDE} ; do
		if [[ -f ${WORKDIR}/piepatch/${i} ]] ; then
			einfo "Excluding piepatch ${i}"
			rm -f "${WORKDIR}"/piepatch/${i} || die "failed to delete ${i}"
		fi
	done
}
