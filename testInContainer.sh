#!/bin/bash
# This can only be run from macOS
swift test --generate-linuxmain # Make sure linux test manifest is up-to-date
docker run --rm -v "$(pwd):/package" --workdir "/package" -it swift:4.1 bash -c "swift test"
