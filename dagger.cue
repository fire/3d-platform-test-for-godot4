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
                        source: "index.docker.io/groupsinfra/gocd-agent-centos-8-groups:docker-gocd-agent-centos-8-groups_84b71558.15"
                    },
                    docker.#Set & {
                        config: {
                            user:    "root"
                            workdir: "/"
                            entrypoint: ["sh"]
                        }
                    },
                    docker.#Copy & {
                        contents: godot.output
                        dest:     "/go/godot"
                    },
                    bash.#Run & {
                        workdir: "/"
                        script: contents: #"""
                        chown -R go /go
                        """#
                    },
                    docker.#Set & {
                        config: {
                            user:    "go"
                            workdir: "/go"
                            entrypoint: ["sh"]
                        }
                    },
                    bash.#Run & {
                        workdir: "/go/godot"
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