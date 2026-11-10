#!/usr/bin/env bash
# Runs the notebook of the demo end to end in the local setup (service `demo`
# of `compose.yaml`), as the README describes it, and checks the results: the
# configuration files that the README asks for, with the services of the
# setup, then all cells of `demo.ipynb`, then the result of the workflow in
# S3 and the tasks that went through proTES. Works on a copy of the
# repository (mounted at `/src`), so that nothing is written to it.
set -euo pipefail

gateway=http://protes:8080
bucket_path=demo/results

work="$(mktemp -d)"
cp -r /src/demo.ipynb /src/images /src/wf-federated "${work}"
cd "${work}"

token="$(curl -fsS 'http://fake-idp:8080/oidc/token?sub=demo-user' | jq -r .access_token)"

cat << EOF > .tes_instances
Funnel @ local-1,http://funnel-1:8000/
Funnel @ local-2,http://funnel-2:8000/
EOF

# Dummy values of the local setup (`compose.yaml`)
cat << EOF > .env
export FUNNEL_SERVER_USER=local-user
export FUNNEL_SERVER_PASSWORD=local-password
export TES_GATEWAY=${gateway}
export TES_TOKEN=${token}
export ACCESS_KEY_ID=local-access-key
export SECRET_ACCESS_KEY=local-secret-key
export ENDPOINT_URL=http://s3:9000
export BUCKET_PATH=${bucket_path}
EOF
chmod 600 .env

echo "Running the notebook..."
status=0
jupyter nbconvert --to notebook --execute --inplace \
  --ExecutePreprocessor.timeout=1800 demo.ipynb || status=$?

# The output of each cell, also if a cell failed
python - << 'EOF'
import json

with open("demo.ipynb", encoding="utf-8") as stream:
    notebook = json.load(stream)
for index, cell in enumerate(notebook["cells"]):
    if cell["cell_type"] != "code":
        continue
    print(f"---------- Cell {index} ----------")
    print("".join(cell["source"]))
    print("---------- Output ----------")
    for output in cell.get("outputs", []):
        print("".join(output.get("text", "")), end="")
        if output.get("output_type") == "error":
            print(f"ERROR: {output.get('ename')} {output.get('evalue')}")
EOF
if [ "${status}" -ne 0 ]; then
  echo "FAILED: the notebook did not run through" >&2
  exit "${status}"
fi

echo "Checking the result in S3..."
python - "${bucket_path}" << 'EOF'
import sys

import boto3

bucket, _, prefix = sys.argv[1].partition("/")
s3 = boto3.client(
    "s3",
    endpoint_url="http://s3:9000",
    aws_access_key_id="local-access-key",
    aws_secret_access_key="local-secret-key",
)
key = f"{prefix}/demo_outfile_result.txt"
result = s3.get_object(Bucket=bucket, Key=key)["Body"].read().decode().strip()
print(f"s3://{bucket}/{key}: {result}")
if float(result) <= 0:
    sys.exit("FAILED: the mean size of the downloaded files is not positive")
EOF

echo "Checking the tasks of the gateway..."
tasks="$(curl -fsS -H "Authorization: Bearer ${token}" \
  "${gateway}/ga4gh/tes/v1/tasks?view=MINIMAL")"
echo "${tasks}" | jq -c '.tasks[] | {id, state}'
# One task for each of the four downloads, and one to gather the sizes
echo "${tasks}" | jq -e '(.tasks | length) >= 5 and all(.tasks[]; .state == "COMPLETE")' > /dev/null \
  || { echo "FAILED: expected at least 5 tasks, all COMPLETE" >&2; exit 1; }

echo "PASSED: the demo ran end to end"
