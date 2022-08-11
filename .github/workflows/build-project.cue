name: "Dagger Export"

on:
  push:
    branches: [ main ]

jobs:
  build:
    name: "Build"
    runs-on: ubuntu-latest
    # Set cache export environment
    env:
      DAGGER_CACHE_FROM: type=gha,scope=${{github.job}}-${{github.ref}}-${{github.sha}},dest=.dagger_cache
      DAGGER_CACHE_TO: type=gha,mode=max,scope=${{github.job}}-${{github.ref}}-${{github.sha}},dest=.dagger_cache
    steps:
      # Upload cache on completion and check it out now
      - name: Load dagger cache directory
        id: linux-editor-cache
        uses: actions/cache@v2
        with:
          path: ${{github.workspace}}/.dagger_cache/
          key: ${{github.job}}-${{github.ref}}-${{github.sha}}
          restore-keys: |
            ${{github.job}}-${{github.ref}}-${{github.sha}}
            ${{github.job}}-${{github.ref}}
            ${{github.job}}

      - name: Checkout
        uses: actions/checkout@v2

      - name: "Run Dagger"
        uses: dagger/dagger-for-github@v3
        with:
          cmds: |
             do build