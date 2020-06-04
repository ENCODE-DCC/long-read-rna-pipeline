#!/bin/bash

set -e

echo "Running cromwell $CROMWELL, womtool $WOMTOOL and image $TAG"

if [[ $# -eq 1 ]]; then
    caper run $1 --docker $TAG --cromwell $CROMWELL --womtool $WOMTOOL --options ./tests/cromwell_options.json
fi

if [[ $# -eq 2 ]]; then
    caper run $1 --docker $TAG --cromwell $CROMWELL --womtool $WOMTOOL -i $2 --options ./tests/cromwell_options.json
fi
