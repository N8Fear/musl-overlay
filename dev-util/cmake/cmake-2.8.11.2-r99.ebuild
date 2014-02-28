# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-util/cmake/cmake-2.8.11.2.ebuild,v 1.8 2014/01/27 12:10:44 hattya Exp $

EAPI=5

CMAKE_REMOVE_MODULES="no"
inherit elisp-common toolchain-funcs eutils versionator cmake-utils virtualx

MY_PV=${PV/_/-}
MY_P=${PN}-${MY_PV}

DESCRIPTION="Cross platform Make"
HOMEPAGE="http://www.cmake.org/"
SRC_URI="http://www.cmake.org/files/v$(get_version_component_range 1-2)/${MY_P}.tar.gz"

LICENSE="CMake"
KEYWORDS="amd64 arm ~mips x86"
SLOT="0"
IUSE="emacs ncurses qt4 qt5 vim-syntax"

REQUIRED_USE="?? ( qt4 qt5 )"

DEPEND="
	>=app-arch/libarchive-2.8.0:=
	>=dev-libs/expat-2.0.1
	>=net-misc/curl-7.20.0-r1[ssl]
	sys-libs/zlib
	virtual/pkgconfig
	ncurses? ( sys-libs/ncurses )
	qt4? (
		dev-qt/qtcore:4
		dev-qt/qtgui:4
	)
	qt5? (
		dev-qt/qtcore:5
		dev-qt/qtgui:5
		dev-qt/qtwidgets:5
	)
"
RDEPEND="${DEPEND}
	emacs? ( virtual/emacs )
	vim-syntax? (
		|| (
			app-editors/vim
			app-editors/gvim
		)
	)
"

S="${WORKDIR}/${MY_P}"

SITEFILE="50${PN}-gentoo.el"
VIMFILE="${PN}.vim"

CMAKE_BINARY="${S}/Bootstrap.cmk/cmake"

PATCHES=(
	"${FILESDIR}"/${PN}-2.6.3-fix_broken_lfs_on_aix.patch
	"${FILESDIR}"/${PN}-2.6.3-no-duplicates-in-rpath.patch
	"${FILESDIR}"/${PN}-2.8.0-darwin-default-install_name.patch
	"${FILESDIR}"/${PN}-2.8.7-FindLAPACK.patch
	"${FILESDIR}"/${PN}-2.8.8-FindPkgConfig.patch
	"${FILESDIR}"/${PN}-2.8.10-darwin-bundle.patch
	"${FILESDIR}"/${PN}-2.8.10-darwin-isysroot.patch
	"${FILESDIR}"/${PN}-2.8.10-desktop.patch
	"${FILESDIR}"/${PN}-2.8.10-libform.patch
	"${FILESDIR}"/${PN}-2.8.10.2-FindPythonInterp.patch
	"${FILESDIR}"/${PN}-2.8.10.2-FindPythonLibs.patch
	"${FILESDIR}"/${PN}-2.8.11-FindBLAS.patch
	"${FILESDIR}"/${PN}-2.8.11-FindBoost-python.patch
	"${FILESDIR}"/${PN}-2.8.11-FindImageMagick.patch
	"${FILESDIR}"/${PN}-2.8.11-more-no_host_paths.patch
	"${FILESDIR}"/${PN}-2.8.11.2-hppa-bootstrap.patch
	"${FILESDIR}"/${PN}-2.8.11.2-execinfo.patch
)

cmake_src_bootstrap() {
	# Cleanup args to extract only JOBS.
	# Because bootstrap does not know anything else.
	echo ${MAKEOPTS} | egrep -o '(\-j|\-\-jobs)(=?|[[:space:]]*)[[:digit:]]+' > /dev/null
	if [ $? -eq 0 ]; then
		par_arg=$(echo ${MAKEOPTS} | egrep -o '(\-j|\-\-jobs)(=?|[[:space:]]*)[[:digit:]]+' | tail -n1 | egrep -o '[[:digit:]]+')
		par_arg="--parallel=${par_arg}"
	else
		par_arg="--parallel=1"
	fi

	tc-export CC CXX LD

	# bootstrap script isn't exactly /bin/sh compatible
	${CONFIG_SHELL:-sh} ./bootstrap \
		--prefix="${T}/cmakestrap/" \
		${par_arg} \
		|| die "Bootstrap failed"
}

cmake_src_test() {
	# fix OutDir and SelectLibraryConfigurations tests
	# these are altered thanks to our eclass
	sed -i -e 's:#IGNORE ::g' \
		"${S}"/Tests/{OutDir,CMakeOnly/SelectLibraryConfigurations}/CMakeLists.txt \
		|| die

	pushd "${CMAKE_BUILD_DIR}" > /dev/null

	local ctestargs
	[[ -n ${TEST_VERBOSE} ]] && ctestargs="--extra-verbose --output-on-failure"

	# Excluded tests:
	#    BootstrapTest: we actualy bootstrap it every time so why test it.
	#    CTest.updatecvs, which fails to commit as root
	#    Qt4Deploy, which tries to break sandbox and ignores prefix
	#    TestUpload, which requires network access
	"${CMAKE_BUILD_DIR}"/bin/ctest ${ctestargs} \
		-E "(BootstrapTest|CTest.UpdateCVS|Qt4Deploy|TestUpload)" \
		|| die "Tests failed"

	popd > /dev/null
}

pkg_setup() {
	# bug 387227
	addpredict /proc/self/coredump_filter
}

src_prepare() {
	cmake-utils_src_prepare

	# disable running of cmake in boostrap command
	sed -i \
		-e '/"${cmake_bootstrap_dir}\/cmake"/s/^/#DONOTRUN /' \
		bootstrap || die "sed failed"

	# Add gcc libs to the default link paths
	sed -i \
		-e "s|@GENTOO_PORTAGE_GCCLIBDIR@|${EPREFIX}/usr/${CHOST}/lib/|g" \
		-e "s|@GENTOO_PORTAGE_EPREFIX@|${EPREFIX}/|g" \
		Modules/Platform/{UnixPaths,Darwin}.cmake || die "sed failed"

	cmake_src_bootstrap
}

src_configure() {
	# make things work with gentoo java setup
	# in case java-config cannot be run, the variable just becomes unset
	# per bug #315229
	export JAVA_HOME=$(java-config -g JAVA_HOME 2> /dev/null)

	local mycmakeargs=(
		-DCMAKE_USE_SYSTEM_LIBRARIES=ON
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}"/usr
		-DCMAKE_DOC_DIR=/share/doc/${PF}
		-DCMAKE_MAN_DIR=/share/man
		-DCMAKE_DATA_DIR=/share/${PN}
		$(cmake-utils_use_build ncurses CursesDialog)
	)

	if use qt4 || use qt5 ; then
		mycmakeargs+=(
			-DBUILD_QtDialog=ON
			$(cmake-utils_use_find_package qt5 Qt5Widgets)
		)
	fi
	cmake-utils_src_configure
}

src_compile() {
	cmake-utils_src_compile
	use emacs && elisp-compile Docs/cmake-mode.el
}

src_test() {
	VIRTUALX_COMMAND="cmake_src_test" virtualmake
}

src_install() {
	cmake-utils_src_install
	if use emacs; then
		elisp-install ${PN} Docs/cmake-mode.el Docs/cmake-mode.elc
		elisp-site-file-install "${FILESDIR}/${SITEFILE}"
	fi
	if use vim-syntax; then
		insinto /usr/share/vim/vimfiles/syntax
		doins Docs/cmake-syntax.vim

		insinto /usr/share/vim/vimfiles/indent
		doins Docs/cmake-indent.vim

		insinto /usr/share/vim/vimfiles/ftdetect
		doins "${FILESDIR}/${VIMFILE}"
	fi
}

pkg_postinst() {
	use emacs && elisp-site-regen
}

pkg_postrm() {
	use emacs && elisp-site-regen
}
