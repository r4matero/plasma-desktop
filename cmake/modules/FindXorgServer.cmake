# - Find xorg-server's headers.
# This module defines the following variables:
#
#  XORGSERVER_FOUND        - true if xserver was found
#  XORGSERVER_INCLUDE_DIRS - include path for xserver
#  There are no libraries, just a header file
#
# Copyright (c) 2020 Andreas Sturmlechner <asturm@gentoo.org>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of the University nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

find_package(PkgConfig)
pkg_check_modules(PC_XORGSERVER xorg-server)

find_path(XORGSERVER_INCLUDE_DIRS
    NAMES xserver-properties.h
    HINTS ${PC_XORGSERVER_INCLUDE_DIRS} ${PC_XORGSERVER_INCLUDEDIR}
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(XORGSERVER REQUIRED_VARS XORGSERVER_INCLUDE_DIRS)

mark_as_advanced(XORGSERVER_INCLUDE_DIRS)
