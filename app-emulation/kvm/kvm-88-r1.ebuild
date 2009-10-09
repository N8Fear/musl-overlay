# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/kvm/kvm-88-r1.ebuild,v 1.2 2009/07/27 18:04:51 dang Exp $

EAPI="2"

inherit eutils flag-o-matic toolchain-funcs linux-info

MY_PN="qemu-${PN}-devel"
MY_P="${MY_PN}-${PV}"

# Patchset git repo is at http://github.com/dang/kvm-patches/tree/master
PATCHSET="kvm-patches-20090725"
SRC_URI="mirror://sourceforge/kvm/${MY_P}.tar.gz
	http://dev.gentoo.org/~dang/files/${PATCHSET}.tar.gz"

DESCRIPTION="Kernel-based Virtual Machine userland tools"
HOMEPAGE="http://www.linux-kvm.org"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="-* ~amd64 ~x86"
# Add bios back when it builds again
IUSE="alsa bluetooth esd gnutls havekernel +modules ncurses pulseaudio +sdl vde"
RESTRICT="test"

RDEPEND="sys-libs/zlib
	sys-apps/pciutils
	alsa? ( >=media-libs/alsa-lib-1.0.13 )
	esd? ( media-sound/esound )
	pulseaudio? ( media-sound/pulseaudio )
	gnutls? ( net-libs/gnutls )
	ncurses? ( sys-libs/ncurses )
	sdl? ( >=media-libs/libsdl-1.2.11[X] )
	vde? ( net-misc/vde )
	bluetooth? ( net-wireless/bluez )
	modules? ( ~app-emulation/kvm-kmod-${PV} )"

#    bios? (
#        sys-devel/dev86
#        dev-lang/perl
#        sys-power/iasl
#    )
DEPEND="${RDEPEND}
	gnutls? ( dev-util/pkgconfig )
	app-text/texi2html"

QA_TEXTRELS="usr/bin/kvm"

S="${WORKDIR}/${MY_P}"

pkg_setup() {
	if use havekernel && use modules ; then
		ewarn "You have the 'havekernel' and 'modules' use flags enabled."
		ewarn "'havekernel' trumps 'modules'; the kvm modules will not"
		ewarn "be built.  You must ensure you have a compatible kernel"
		ewarn "with the kvm modules on your own"
	elif use havekernel ; then
		ewarn "You have the 'havekernel' use flag set.  This means you"
		ewarn "must ensure you have a compatible kernel on your own."
	elif use modules ; then
		:;
	elif kernel_is lt 2 6 25; then
		eerror "This version of KVM requres a host kernel of 2.6.25 or higher."
		eerror "Either upgrade your kernel, or enable the 'modules' USE flag."
		die "kvm version not compatible"
	elif ! linux_chkconfig_present KVM; then
		eerror "Please enable KVM support in your kernel, found at:"
		eerror
		eerror "  Virtualization"
		eerror "    Kernel-based Virtual Machine (KVM) support"
		eerror
		eerror "or enable the 'modules' USE flag."
		die "KVM support not detected!"
	fi

	enewgroup kvm
}

src_prepare() {
	# prevent docs to get automatically installed
	sed -i '/$(DESTDIR)$(docdir)/d' Makefile
	# Alter target makefiles to accept CFLAGS set via flag-o
	sed -i 's/^\(C\|OP_C\|HELPER_C\)FLAGS=/\1FLAGS+=/' \
		Makefile Makefile.target
	[[ -x /sbin/paxctl ]] && \
		sed -i 's/^VL_LDFLAGS=$/VL_LDFLAGS=-Wl,-z,execheap/' \
			Makefile.target

	# Kernel patch; doesn't apply
	rm "${WORKDIR}/${PATCHSET}"/07_all_kernel-longmode.patch
	# evdev patch is upstream
	rm "${WORKDIR}/${PATCHSET}"/10_all_evdev_keycode_map.patch

	epatch "${FILESDIR}"/${P}-link-with-cflags.patch

	# apply patchset
	EPATCH_SOURCE="${WORKDIR}/${PATCHSET}"
	EPATCH_SUFFIX="patch"
	epatch

}

src_configure() {
	local mycc conf_opts audio_opts

	audio_opts="oss"
	use gnutls || conf_opts="$conf_opts --disable-vnc-tls"
	use ncurses || conf_opts="$conf_opts --disable-curses"
	use sdl || conf_opts="$conf_opts --disable-sdl"
	use vde || conf_opts="$conf_opts --disable-vde"
	use bluetooth || conf_opts="$conf_opts --disable-bluez"
	use alsa && audio_opts="alsa $audio_opts"
	use esd && audio_opts="esd $audio_opts"
	use pulseaudio && audio_opts="pa $audio_opts"
	use sdl && audio_opts="sdl $audio_opts"
	conf_opts="$conf_opts --prefix=/usr"
	conf_opts="$conf_opts --disable-strip"
	conf_opts="$conf_opts --disable-xen"
#	conf_opts="$conf_opts --extra-cflags='${CFLAGS}'"
#	conf_opts="$conf_opts --extra-ldflags='${LDFLAGS}'"

	filter-flags -fPIE
	filter-flags -fstack-protector #286587

	./configure ${conf_opts} --audio-drv-list="$audio_opts" || die "econf failed"
}

src_install() {
	# Fix docs manually (dynamically generated during compile)
	sed -i -e 's/QEMU/KVM/g;\
			s/qemu/kvm/g;\
			s/Qemu/Kvm/g;\
			s/kvm-\([a-z\-]*\)\.texi/qemu-\1\.texi/g' \
		*.texi *.1 *.8

	emake DESTDIR="${D}" install || die "make install failed"

	dobin "${S}/kvm_stat"

	mv "${D}"/usr/share/man/man1/qemu.1 "${D}"/usr/share/man/man1/kvm.1
	mv "${D}"/usr/share/man/man1/qemu-img.1 "${D}"/usr/share/man/man1/kvm-img.1
	mv "${D}"/usr/share/man/man8/qemu-nbd.8 "${D}"/usr/share/man/man8/kvm-nbd.8
	mv "${D}"/usr/bin/qemu-img "${D}"/usr/bin/kvm-img
	mv "${D}"/usr/bin/qemu-nbd "${D}"/usr/bin/kvm-nbd
	mv "${D}"/usr/bin/qemu-io "${D}"/usr/bin/kvm-io
	rm "${D}"/usr/share/kvm/openbios-{sparc32,sparc64,ppc}

	insinto /etc/udev/rules.d/
	doins kvm/scripts/65-kvm.rules

	insinto /etc/kvm/
	insopts -m0755
	newins kvm/scripts/qemu-ifup kvm-ifup
	newins kvm/scripts/qemu-ifdown kvm-ifdown

	dodoc pc-bios/README
	newdoc qemu-doc.html kvm-doc.html
	newdoc qemu-tech.html kvm-tech.html
}

pkg_postinst() {
	elog "If you don't have kvm compiled into the kernel, make sure you have"
	elog "the kernel module loaded before running kvm. The easiest way to"
	elog "ensure that the kernel module is loaded is to load it on boot."
	elog "For AMD CPUs the module is called 'kvm-amd'"
	elog "For Intel CPUs the module is called 'kvm-intel'"
	elog "Please review /etc/conf.d/modules for how to load these"
	elog
	elog "Make sure your user is in the 'kvm' group"
	elog "Just run 'gpasswd -a <USER> kvm', then have <USER> re-login."
	elog
	elog "You will need the Universal TUN/TAP driver compiled into your"
	elog "kernel or loaded as a module to use the virtual network device"
	elog "if using -net tap.  You will also need support for 802.1d"
	elog "Ethernet Bridging and a configured bridge if using the provided"
	elog "kvm-ifup script from /etc/kvm."
	echo
}
