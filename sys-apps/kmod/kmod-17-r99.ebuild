# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/kmod/kmod-17.ebuild,v 1.9 2014/05/15 20:06:25 maekke Exp $

EAPI=5

PYTHON_COMPAT=( python{2_7,3_2,3_3,3_4} )

inherit bash-completion-r1 eutils multilib python-r1

if [[ ${PV} == 9999* ]]; then
	EGIT_REPO_URI="git://git.kernel.org/pub/scm/utils/kernel/${PN}/${PN}.git"
	inherit autotools git-2
else
	SRC_URI="mirror://kernel/linux/utils/kernel/kmod/${P}.tar.xz"
	KEYWORDS="amd64 arm ~mips ppc x86"
	inherit libtool
fi

DESCRIPTION="library and tools for managing linux kernel modules"
HOMEPAGE="http://git.kernel.org/?p=utils/kernel/kmod/kmod.git"

LICENSE="LGPL-2"
SLOT="0"
IUSE="debug doc lzma python static-libs +tools zlib"

# Upstream does not support running the test suite with custom configure flags.
# I was also told that the test suite is intended for kmod developers.
# So we have to restrict it.
# See bug #408915.
RESTRICT="test"

RDEPEND="!sys-apps/module-init-tools
	!sys-apps/modutils
	!<sys-apps/openrc-0.12
	lzma? ( >=app-arch/xz-utils-5.0.4-r1 )
	python? ( ${PYTHON_DEPS} )
	zlib? ( >=sys-libs/zlib-1.2.6 )" #427130
DEPEND="${RDEPEND}
	doc? ( dev-util/gtk-doc )
	lzma? ( virtual/pkgconfig )
	python? (
		dev-python/cython[${PYTHON_USEDEP}]
		virtual/pkgconfig
		)
	zlib? ( virtual/pkgconfig )"
if [[ ${PV} == 9999* ]]; then
	DEPEND="${DEPEND}
		dev-libs/libxslt"
fi

REQUIRED_USE="python? ( ${PYTHON_REQUIRED_USE} )"

src_prepare() {
	if [ ! -e configure ]; then
		if use doc; then
			gtkdocize --copy --docdir libkmod/docs || die
		else
			touch libkmod/docs/gtk-doc.make
		fi
		eautoreconf
	else
		epatch "${FILESDIR}"/${PN}-15-dynamic-kmod.patch #493630
		epatch "${FILESDIR}"/${PN}-15-use-strndup.patch
		elibtoolize
	fi

	# Restore possibility of running --enable-static wrt #472608
	sed -i \
		-e '/--enable-static is not supported by kmod/s:as_fn_error:echo:' \
		configure || die
}

src_configure() {
	local myeconfargs=(
		--bindir=/bin
		--with-rootlibdir="/$(get_libdir)"
		--enable-shared
		$(use_enable static-libs static)
		$(use_enable tools)
		$(use_enable debug)
		$(use_enable doc gtk-doc)
		$(use_with lzma xz)
		$(use_with zlib)
		--with-bashcompletiondir="$(get_bashcompdir)"
	)

	local ECONF_SOURCE="${S}"

	kmod_configure() {
		mkdir -p "${BUILD_DIR}" || die
		run_in_build_dir econf "${myeconfargs[@]}" "$@"
	}

	BUILD_DIR="${WORKDIR}/build"
	kmod_configure --disable-python

	if use python; then
		python_parallel_foreach_impl kmod_configure --enable-python
	fi
}

src_compile() {
	if [[ ${PV} != 9999* ]]; then
		# Force -j1 because of -15-dynamic-kmod.patch, likely caused by lack of eautoreconf
		# wrt #494806
		local MAKEOPTS="${MAKEOPTS} -j1"
	fi

	emake -C "${BUILD_DIR}"

	if use python; then
		local native_builddir=${BUILD_DIR}

		python_compile() {
			emake -C "${BUILD_DIR}" -f Makefile -f - python \
				VPATH="${native_builddir}:${S}" \
				native_builddir="${native_builddir}" \
				libkmod_python_kmod_{kmod,list,module,_util}_la_LIBADD='$(PYTHON_LIBS) $(native_builddir)/libkmod/libkmod.la' \
				<<< 'python: $(pkgpyexec_LTLIBRARIES)'
		}

		python_foreach_impl python_compile
	fi
}

src_install() {
	emake -C "${BUILD_DIR}" DESTDIR="${D}" install

	if use python; then
		local native_builddir=${BUILD_DIR}

		python_install() {
			emake -C "${BUILD_DIR}" DESTDIR="${D}" \
				VPATH="${native_builddir}:${S}" \
				install-pkgpyexecLTLIBRARIES \
				install-dist_pkgpyexecPYTHON
		}

		python_foreach_impl python_install
	fi

	prune_libtool_files --modules

	if use tools; then
		local bincmd sbincmd
		for sbincmd in depmod insmod lsmod modinfo modprobe rmmod; do
			dosym /bin/kmod /sbin/${sbincmd}
		done

		# These are also usable as normal user
		for bincmd in lsmod modinfo; do
			dosym kmod /bin/${bincmd}
		done
	fi

	cat <<-EOF > "${T}"/usb-load-ehci-first.conf
	softdep uhci_hcd pre: ehci_hcd
	softdep ohci_hcd pre: ehci_hcd
	EOF

	insinto /lib/modprobe.d
	doins "${T}"/usb-load-ehci-first.conf #260139

	doinitd "${FILESDIR}"/kmod-static-nodes
}

pkg_postinst() {
	if [[ -L ${ROOT%/}/etc/runlevels/boot/static-nodes ]]; then
		ewarn "Removing old conflicting static-nodes init script from the boot runlevel"
		rm -f "${ROOT%/}"/etc/runlevels/boot/static-nodes
	fi

	# Add kmod to the runlevel automatically if this is the first install of this package.
	if [[ -z ${REPLACING_VERSIONS} ]]; then
		if [[ ! -d ${ROOT%/}/etc/runlevels/sysinit ]]; then
			mkdir -p "${ROOT%/}"/etc/runlevels/sysinit
		fi
		if [[ -x ${ROOT%/}/etc/init.d/kmod-static-nodes ]]; then
			ln -s /etc/init.d/kmod-static-nodes "${ROOT%/}"/etc/runlevels/sysinit/kmod-static-nodes
		fi
	fi

	if [[ -e ${ROOT%/}/etc/runlevels/sysinit ]]; then
		if [[ ! -e ${ROOT%/}/etc/runlevels/sysinit/kmod-static-nodes ]]; then
			ewarn
			ewarn "You need to add kmod-static-nodes to the sysinit runlevel for"
			ewarn "kernel modules to have required static nodes!"
			ewarn "Run this command:"
			ewarn "\trc-update add kmod-static-nodes sysinit"
		fi
	fi
}
