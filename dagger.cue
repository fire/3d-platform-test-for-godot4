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
dagger.#Plan & {
    client: filesystem: ".": read: {
        contents: dagger.#FS
    }
	actions: {
        build: {
            docker.#Build & {
                steps: [
                    docker.#Pull & {
                        source: "fedora:35"
                    },
                    docker.#Set & {
                        config: {
                            user:    "root"
                            workdir: "/"
                            entrypoint: ["sh"]
                        }
                    },
                    bash.#Run & {
                        workdir: "/go/godot"
                        script: contents: #"""
                        yum install unzip -y
                        """#
                    },
                    bash.#Run & {
                        workdir: "/go/godot"
                        script: contents: #"""
                        cd /usr/local/bin && curl -L -o butler.zip https://broth.itch.ovh/butler/linux-amd64/LATEST/archive/default && unzip butler.zip && rm butler.zip && butler -V && butler -V && cd && butler -V
                        """#
                    },
                    bash.#Run & {
                        workdir: "/go/godot"
                        script: contents: #"""
                        yum group install -y "Development Tools"
                        """#
                    },
                    bash.#Run & {
                        workdir: "/go/godot"
                        script: contents: #"""
                        yum install -y git-lfs automake autoconf libtool yasm wine mono-devel cmake python3-scons clang glibc-devel.i686 libgcc.i686 libstdc++.i686 mingw64-gcc-c++ mingw32-gcc mingw32-gcc-c++ python3-pip mingw64-winpthreads mingw32-winpthreads mingw64-winpthreads-static mingw32-winpthreads-static libstdc++-static mingw64-filesystem mingw32-filesystem bash libX11-devel libXcursor-devel libXrandr-devel libXinerama-devel libXi-devel mesa-libGL-devel alsa-lib-devel pulseaudio-libs-devel freetype-devel openssl-devel libudev-devel mesa-libGLU-devel libpng-devel xar-devel llvm-devel clang llvm-devel libxml2-devel libuuid-devel openssl-devel bash patch libstdc++-static make git bzip2 xz java-openjdk yasm xorg-x11-server-Xvfb pkgconfig mesa-dri-drivers java-1.8.0-openjdk-devel ncurses-compat-libs unzip which gcc gcc-c++ libatomic-static libatomic ccache ninja-build
                        """#
                    },
                    bash.#Run & {
                        workdir: "/go/godot"
                        script: contents: #"""
                        alternatives --set ld /usr/bin/ld.gold && git lfs install && alternatives --set python /usr/bin/python3 && ln -s /usr/bin/scons-3 /usr/local/bin/scons
                        """#
                    },                    
                    bash.#Run & {
                        workdir: "/go/godot"
                        script: contents: #"""
                        git clone https://github.com/emscripten-core/emsdk /opt/emsdk && /opt/emsdk/emsdk install latest && /opt/emsdk/emsdk activate latest && curl -L -o ispc.tgz 'https://github.com/ispc/ispc/releases/download/v1.15.0/ispc-v1.15.0-linux.tar.gz' && tar -zxf ispc.tgz ispc-v1.15.0-linux/bin/ispc && mv ispc-v1.15.0-linux/bin/ispc /usr/local/bin/ispc && rmdir -p ispc-v1.15.0-linux/bin
                        """#
                    },                    
                    bash.#Run & {
                        workdir: "/go/godot"
                        script: contents: #"""
                        # https://dl.google.com/android/repository/commandlinetools-linux-6514223_latest.zip
                        """#
                    },                 
                    bash.#Run & {
                        workdir: "/go/godot"
                        script: contents: #"""
                        curl -LO https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip && unzip sdk-tools-linux-4333796.zip -d /opt/android && rm sdk-tools-linux-4333796.zip && yes | /opt/android/tools/bin/sdkmanager --licenses && /opt/android/tools/bin/sdkmanager ndk-bundle 'platforms;android-23' 'build-tools;19.1.0' 'build-tools;28.0.3' 'platforms;android-28'
                        """#
                    },
                    bash.#Run & {
                        workdir: "/"
                        script: contents: #"""
                        mkuser groups
                        mkdir /groups
                        chown -R groups /groups
                        """#
                    },
                    docker.#Copy & {
                        contents: godot.output
                        dest:     "/groups/godot"
                    },
                    docker.#Set & {
                        config: {
                            user:    "groups"
                            workdir: "/groups"
                            entrypoint: ["sh"]
                        }
                    },
                    bash.#Run & {
                        workdir: "/groups/godot"
                        script: contents: #"""
                        git config --global url.git@gitlab.com:.insteadOf https://gitlab.com/
                        """#
                    },
                    bash.#Run & {
                        workdir: "/groups/godot"
                        script: contents: #"""
                        pwd
                        whoami
                        ls -al
                        scons target=release_debug
                        """#
                    }
                ]
            }
        }
    }
}