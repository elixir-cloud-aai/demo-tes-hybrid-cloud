#!/usr/bin/env bash
# Runs the notebook of the demo end to end in the local setup (service `demo`
# of `compose.yaml`), and checks the results: it writes the configuration
# files that the README asks for, with the services and the dummy credentials
# of the setup (which must match `compose.yaml` and `funnel.yaml`), runs all
# cells of `demo.ipynb`, then checks the result of the workflow in S3 and the
# tasks that went through proTES. It prints the output of all cells. Works on
# a copy of the repository (mounted at `/src`), so that nothing is written to
# it.
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

# Tasks of the gateway from earlier runs, which the checks below leave out
tasks_url="${gateway}/ga4gh/tes/v1/tasks?view=MINIMAL"
earlier="$(curl -fsS -H "Authorization: Bearer ${token}" "${tasks_url}" | jq -c '[.tasks[]?.id]')"

echo "Running the notebook..."
# Keeps the outputs of all cells, also if a cell fails or times out (checked
# below)
jupyter nbconvert --to notebook --execute --inplace --allow-errors \
  --ExecutePreprocessor.timeout=1800 \
  --ExecutePreprocessor.interrupt_on_timeout=True demo.ipynb

# The output of each cell; fails if a cell failed
status=0
python - << 'EOF' || status=$?
import json
import sys

failed = False

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
            failed = True
sys.exit(1 if failed else 0)
EOF
if [ "${status}" -ne 0 ]; then
  echo "FAILED: the notebook did not run through" >&2
  exit "${status}"
fi

echo "Checking the result in S3..."
set -a
source .env
set +a
python - << 'EOF'
import os
import sys

import boto3

bucket, _, prefix = os.environ["BUCKET_PATH"].partition("/")
s3 = boto3.client(
    "s3",
    endpoint_url=os.environ["ENDPOINT_URL"],
    aws_access_key_id=os.environ["ACCESS_KEY_ID"],
    aws_secret_access_key=os.environ["SECRET_ACCESS_KEY"],
)
key = f"{prefix}/demo_outfile_result.txt"
result = s3.get_object(Bucket=bucket, Key=key)["Body"].read().decode().strip()
print(f"s3://{bucket}/{key}: {result}")
if float(result) <= 0:
    sys.exit("FAILED: the mean size of the downloaded files is not positive")
EOF

echo "Checking the tasks of the gateway..."
tasks="$(curl -fsS -H "Authorization: Bearer ${token}" "${tasks_url}" \
  | jq -c --argjson earlier "${earlier}" \
  '[.tasks[]? | select(.id as $id | $earlier | index($id) | not) | {id, state}]')"
echo "${tasks}" | jq -c '.[]'
# One task for each of the four downloads, and one to gather the sizes
echo "${tasks}" | jq -e 'length >= 5 and all(.[]; .state == "COMPLETE")' > /dev/null \
  || { echo "FAILED: expected at least 5 new tasks, all COMPLETE" >&2; exit 1; }

echo "PASSED: the demo ran end to end"
