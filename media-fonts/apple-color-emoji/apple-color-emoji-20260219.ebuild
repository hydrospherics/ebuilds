# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit font

DESCRIPTION="Apple Color Emoji fonts used by iOS and macOS"
HOMEPAGE="https://github.com/samuelngs/apple-emoji-ttf"

MY_TAG="macos-26-20260219-2aa12422"
SRC_URI="https://github.com/samuelngs/apple-emoji-ttf/releases/download/${MY_TAG}/AppleColorEmoji-Linux.ttf -> AppleColorEmoji-${MY_TAG}.ttf"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="amd64 ~arm arm64 ~loong ppc64 ~riscv x86"
S="${WORKDIR}"
RESTRICT="binchecks strip"

FONT_SUFFIX="ttf"
FONT_S="${S}"
FONT_CONF=( "${FILESDIR}/75-apple-color-emoji.conf" )

src_unpack() {
	cp "${DISTDIR}/AppleColorEmoji-${MY_TAG}.ttf" "${S}/apple-color-emoji.ttf" || die
}

src_compile() { :; }

src_install() {
	FONT_S="${S}"
	font_src_install
}