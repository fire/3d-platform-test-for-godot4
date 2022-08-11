// MIT License

// Copyright (c) 2022 K. S. Ernest (iFire) Lee

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

package main

import (
	"dagger.io/dagger"
    "dagger.io/dagger/core"
    "universe.dagger.io/bash"
    "universe.dagger.io/docker"
)

godot: {
    core.#GitPull & {
        remote: "https://github.com/V-Sekai/godot.git"
        ref: "groups-4.x.2022-08-10T194237Z"
    }
}
godot_groups_modules: {
    core.#GitPull & {
        remote: "https://github.com/V-Sekai/godot-modules-groups.git"
        ref: "c3efacdb70f74f43ab2d7a58dd309dc466ca836c"
    }
}

fetch_godot: {
    docker.#Build & {
        steps: [
            docker.#Pull & {
                source: "fedora:35"
            },
            docker.#Set & {
                config: {
                    user: "root"
                    workdir: "/"
                    entrypoint: ["sh"]
                }
            },
            bash.#Run & {
                workdir: "/groups/godot"
                script: contents: #"""
                yum install unzip -y
                """#
            },
            bash.#Run & {
                workdir: "/groups/godot"
                script: contents: #"""
                cd /usr/local/bin && curl -L -o butler.zip https://broth.itch.ovh/butler/linux-amd64/LATEST/archive/default && unzip butler.zip && rm butler.zip && butler -V && butler -V && cd && butler -V
                """#
            },
            bash.#Run & {
                workdir: "/groups/godot"
                script: contents: #"""
                yum group install -y "Development Tools"
                """#
            },
            bash.#Run & {
                workdir: "/groups/godot"
                script: contents: #"""
                yum install -y git-lfs automake autoconf libtool yasm cmake python3-scons clang glibc-devel.i686 libgcc.i686 libstdc++.i686 mingw64-gcc-c++ mingw32-gcc mingw32-gcc-c++ python3-pip mingw64-winpthreads mingw32-winpthreads mingw64-winpthreads-static mingw32-winpthreads-static libstdc++-static mingw64-filesystem mingw32-filesystem bash libX11-devel libXcursor-devel libXrandr-devel libXinerama-devel libXi-devel mesa-libGL-devel alsa-lib-devel pulseaudio-libs-devel freetype-devel openssl-devel libudev-devel mesa-libGLU-devel libpng-devel xar-devel llvm-devel clang llvm-devel libxml2-devel libuuid-devel openssl-devel bash patch libstdc++-static make git bzip2 xz java-openjdk yasm xorg-x11-server-Xvfb pkgconfig mesa-dri-drivers java-1.8.0-openjdk-devel ncurses-compat-libs unzip which gcc gcc-c++ libatomic-static libatomic ccache ninja-build
                """#
            },
            bash.#Run & {
                workdir: "/groups/godot"
                script: contents: #"""
                alternatives --set ld /usr/bin/ld.gold && git lfs install && ln -s /usr/bin/scons-3 /usr/local/bin/scons
                """#
            },                    
            bash.#Run & {
                workdir: "/groups/godot"
                script: contents: #"""
                git clone https://github.com/emscripten-core/emsdk /opt/emsdk && /opt/emsdk/emsdk install latest && /opt/emsdk/emsdk activate latest && curl -L -o ispc.tgz 'https://github.com/ispc/ispc/releases/download/v1.15.0/ispc-v1.15.0-linux.tar.gz' && tar -zxf ispc.tgz ispc-v1.15.0-linux/bin/ispc && mv ispc-v1.15.0-linux/bin/ispc /usr/local/bin/ispc && rmdir -p ispc-v1.15.0-linux/bin
                """#
            },
            bash.#Run & {
                workdir: "/groups/godot"
                script: contents: #"""
                mkdir /opt/llvm-mingw && curl -L https://github.com/mstorsjo/llvm-mingw/releases/download/20220323/llvm-mingw-20220323-ucrt-ubuntu-18.04-x86_64.tar.xz | tar -Jxf - --strip 1 -C /opt/llvm-mingw
                """#
            },
            bash.#Run & {
                workdir: "/"
                script: contents: #"""
                adduser groups
                """#
            },
            docker.#Copy & {
                contents: godot_groups_modules.output
                dest:     "/groups/godot_groups_modules"
            },
            docker.#Copy & {
                contents: godot.output
                dest:     "/groups/godot"
            },
            bash.#Run & {
                workdir: "/"
                script: contents: #"""
                chown -R groups /groups
                """#
            },
            docker.#Set & {
                config: {
                    user:    "groups"
                    workdir: "/groups"
                    entrypoint: ["sh"]
                }
            },
        ]
    }
}

build_godot_linux:
    bash.#Run & {
        input: fetch_godot.output
        workdir: "/groups/godot"
        script: contents: #"""
        scons werror=no platform=linuxbsd target=release_debug -j4 use_lto=no deprecated=no use_static_cpp=yes use_llvm=yes builtin_freetype=yes custom_modules=../godot_groups_modules
        """#
    },
build_godot_windows:
    bash.#Run & {
        input: build_godot_linux.output
        workdir: "/groups/godot"
        script: contents: #"""
        PATH=/opt/llvm-mingw/bin:$PATH scons werror=no platform=windows target=release_debug -j4 use_lto=no deprecated=no use_mingw=yes use_llvm=yes use_thinlto=no warnings=no LINKFLAGS=-Wl,-pdb= CCFLAGS='-Wall -Wno-tautological-compare -g -gcodeview' debug_symbols=no custom_modules=../godot_groups_modules
        """#
    }
dagger.#Plan & {
    client: {
        filesystem: ".": read: {
            contents: dagger.#FS
        }
        filesystem: {
            "build": write: contents: actions.build.export.directories."/groups/build"
        }
    }
	actions: {
        build:
            bash.#Run & {
                    user: "root"
                    mounts: 
                        "Local FS": {
                            contents: client.filesystem.".".read.contents
                            dest: "/groups/project"
                        }
                    input: 
                        build_godot_windows.output
                    script: contents: #"""
                        rm -rf /groups/build
                        cd /groups/godot
                        cp bin/godot.windows.opt.tools.64.exe bin/windows_debug_x86_64.exe && cp bin/godot.windows.opt.tools.64.exe bin/windows_release_x86_64.exe && mingw-strip --strip-debug bin/windows_release_x86_64.exe
                        cp bin/godot.linuxbsd.opt.tools.64.llvm bin/linux_debug.x86_64 && cp bin/godot.linuxbsd.opt.tools.64.llvm bin/linux_cicd.x86_64
                        cp bin/godot.linuxbsd.opt.tools.64.llvm bin/linux_debug.x86_64 && cp bin/godot.linuxbsd.opt.tools.64.llvm bin/linux_release.x86_64 && strip --strip-debug bin/linux_release.x86_64
                        cp -r /groups/godot/bin /groups/build/bin
                        rm -rf /groups/.local/share/godot/export_templates/
                        mkdir -p /groups/.local/share/godot/export_templates/
                        cd /groups/.local/share/godot/export_templates/
                        eval `sed -e "s/ = /=/" /groups/godot/version.py` && declare "_tmp$patch=.$patch" "_tmp0=" "_tmp=_tmp$patch" && echo $major.$minor${!_tmp} > /groups/version.txt
                        VERSION=`cat /groups/version.txt` BASE_DIR=/groups/.local/share/godot/export_templates/ TEMPLATEDIR=$BASE_DIR/$VERSION/ && mkdir -p "$TEMPLATEDIR" && cp /groups/godot/bin/windows_release_x86_64.exe "$TEMPLATEDIR"/windows_release_x86_64 && cp /groups/godot/bin/linux_release.x86_64 "$TEMPLATEDIR"/linux_release.x86_64 && cp /groups/version.txt $BASE_DIR
                        # VERSION=`cat /groups/version.txt` TEMPLATEDIR=/groups/.local/share/godot/export_templates/$VERSION/ && mkdir /groups/pdbs && mv "$TEMPLATEDIR"/templates/*.pdb /groups/pdbs/
                        cp -r /groups/project /groups/build
                        cp -r /groups/.local/share/godot/export_templates/ /groups/build/export_templates/
                        cd /groups/build
                        # mkdir -p /groups/project/.godot/editor && mkdir -p /groups/project/.godot/imported && mkdir `pwd`/export_windows && chmod +x godot.linuxbsd.opt.tools.64.llvm && XDG_DATA_HOME=`pwd`/.local/share/ ./godot.linuxbsd.opt.tools.64.llvm --headless --export "Windows Desktop" `pwd`/export_windows/v_sekai_windows.exe --path /groups/project || [ -f `pwd`/export_windows/v_sekai_windows.exe\ ]
                        # mkdir -p /groups/project/.godot/editor && mkdir -p /groups/project/.godot/imported && mkdir export_linuxbsd && chmod +x godot.linuxbsd.opt.tools.64.llvm && XDG_DATA_HOME=`pwd`/.local/share/ ./godot.linuxbsd.opt.tools.64.llvm --headless --export "Linux/X11" `pwd`/export_linuxbsd/v_sekai_linuxbsd --path /groups/project || [ -f `pwd`/export_linuxbsd/v_sekai_linuxbsd ]
                        """#     
                    export: 
                        directories: 
                            "/groups/build": dagger.#FS
                    always: true
                }
    }
}
