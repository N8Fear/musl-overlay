# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-vcs/git/Attic/git-1.7.0.4.ebuild,v 1.4 2010/07/30 21:01:32 robbat2 dead $

EAPI="4"

inherit toolchain-funcs

DESCRIPTION="GIT - the stupid content tracker, the revision control system heavily used by the Linux kernel team"
HOMEPAGE="http://www.git-scm.com/"
SRC_URI="http://dev.gentoo.org/~blueness/misc/${P}.tgz"
KEYWORDS="amd64 x86"

LICENSE="GPL-2"
SLOT="0"
IUSE=""

RDEPEND="sys-libs/zlib"
DEPEND="${RDEPEND}
	app-arch/cpio"

src_prepare() {
	sed -i \
		-e 's:^\(CFLAGS =\).*$:\1 $(OPTCFLAGS) -Wall:' \
		-e 's:^\(LDFLAGS =\).*$:\1 $(OPTLDFLAGS):' \
		-e 's:^\(CC = \).*$:\1$(OPTCC):' \
		-e 's:^\(AR = \).*$:\1$(OPTAR):' \
		Makefile || die "sed failed"

	sed -i \
		-e '/private-Error.pm/s,^,#,' \
		perl/Makefile.PL

	sed -i 's/DOCBOOK2X_TEXI=docbook2x-texi/DOCBOOK2X_TEXI=docbook2texi.pl/' \
		Documentation/Makefile || die "sed failed"

}

git_emake() {
	emake ${MY_MAKEOPTS} \
		DESTDIR="${D}" \
		OPTCFLAGS="${CFLAGS}" \
		OPTLDFLAGS="${LDFLAGS}" \
		OPTCC="$(tc-getCC)" \
		OPTAR="$(tc-getAR)" \
		prefix=/usr \
		"$@"
}

src_configure() {
	local myopts

	[[ "${CHOST}" == *-uclibc* ]] && \
		myopts="${myopts} NO_NSEC=YesPlease"

	export MY_MAKEOPTS="${myopts}"
}

src_compile() {
	git_emake
}

src_install() {
	git_emake install
}
