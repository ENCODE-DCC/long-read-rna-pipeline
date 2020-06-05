#!/bin/bash

set -e # exit on error

if [ $# -lt 3 ]; then
  echo "Usage: ./test.sh [WDL] [INPUT_JSON] [DOCKER_IMAGE]"
  echo "Make sure to have cromwell-40.jar in your \$PATH as an executable (chmod +x)."
  exit 1
fi

WDL=$1
INPUT=$2
DOCKER_IMAGE=$3

#if [ -f "cromwell-40.jar" ]; then
#    echo "cromwell-40.jar already available, skipping download."
#else
#    wget -N -c https://github.com/broadinstitute/cromwell/releases/download/40/cromwell-40.jar
#fi

CROMWELL_JAR=cromwell-49.jar
BACKEND_CONF=backends/backend.conf
RESULT_PREFIX=$(basename ${INPUT} .json)
METADATA=${RESULT_PREFIX}.metadata.json # metadata
RESULT=${RESULT_PREFIX}.result.json # output

if [ $4 = "docker" ]; then
    # Write workflow option JSON file for docker
    BACKEND=Local
    TMP_WF_OPT=$RESULT_PREFIX.test_longrna_wf_opt.json
    cat > $TMP_WF_OPT << EOM
    {
        "default_runtime_attributes" : {
            "docker" : "$DOCKER_IMAGE"
        }
    }
EOM
fi

java -Dconfig.file=${BACKEND_CONF} -Dbackend.default=${BACKEND} -jar ${CROMWELL_JAR} run ${WDL} -i ${INPUT} -o ${TMP_WF_OPT} -m ${METADATA}

rm -f ${TMP_WF_OPT}
