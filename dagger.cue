package main

import (
	"dagger.io/dagger"
    "dagger.io/dagger/core"
    "universe.dagger.io/bash"
    "universe.dagger.io/docker"
)

dagger.#Plan & {
	actions: {
    deps: {
        godot: {
            core.#GitPull & {
                remote: "https://github.com/V-Sekai/godot.git"
                ref: "groups-4.x.2022-08-10T194237Z"
            }
        }
        engine:
            docker.#Build & {
            steps: [
                docker.#Pull & {
                    source: "index.docker.io/groupsinfra/gocd-agent-centos-8-groups:docker-gocd-agent-centos-8-groups_84b71558.15"
                },
                docker.#Copy & {
                    contents: godot.output
                    dest:     "/go/godot"
                },
            ]
            }
        }
        build: {
            bash.#Run & {
                workdir: "/go/godot"
                input:   deps.engine.output
                script: contents: #"""
                   scons target=release_debug
                   """#
            },
        }
    }
}