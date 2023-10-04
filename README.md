# demo-tes-hybrid-cloud

## Objectives

Demonstrate the federated execution of a Snakemake workflow across a network
of compute centers operationalized through the GA4GH TES API.

> **Note:** This demonstrator was adapted from an [earlier
> demonstrator][tut-cwl] focusing on the execution of a [CWL][lang-cwl]
> workflow.

## Service requirements

The following services were already deployed by ELIXIR for the demo:

| Service | Service Type | Version / Image | Configuration | Comment |
| --- | --- | --- | --- | --- |
| [TESK][soft-tesk] | TES instance | `cerit.io/tes-wes/tesk-api:0.1` | Authorization checks disabled | Deployments for Kubernetes and OpenShift |
| [Funnel][soft-funnel] | TES instance | `0.10.1` (OpenPBS) / commit `#52ef90f` (Slurm) | Basic authentication | Deployments for OpenPBS and Slurm; others possible |
| [proTES][soft-protes] | TES clienet & instance | `elixircloud/protes:20230218` | Authorization checks disabled; all TESK and Funnel instances need to be listed in `tes.service_list` in the app configuration prior to executing the demo |
| ?? | S3 server | ?? | ?? | ?? |

## Client requirements

You can install the demo requirements with Conda or Mamba:

```bash
conda env install -n demo-2023-ecp-f2f -f environment.yml
# or
mamba env install -n demo-2023-ecp-f2f -f environment.yml
```

Reinstall `py-tes` and check out a specific commit:

```bash
pip uninstall -y py-tes
pip install git+https://github.com/ohsu-comp-bio/py-tes.git@5379b2a08bc911f7af55bd835dbd85aad0124c6a
```

Verify the successful installation:

```bash
curl --version
jq --version
jupyter --version
jupyter-lab --version
snakemake --version
```

Next, you need to create a listing of the available TES instances in a
comma-seprated file `.tes_instances`. Two fields/columns are required, a
description of the TES instance, and the URL pointing to it.

> You can use the following command to create such a file, but make sure to
> replace the example contents and do not use commas in the name/description
> field:

```bash
cat << "EOF" > .tes_instances
Funnel/Slurm @ YourNode,https://tes.your-node.org/
Funnel/PBS @ YetAnotherNode,https://tes.yet-another-node.org/
TESK/Kubernetes @ OtherNode,https://tes.other-node.org/
EOF
```

You will also need to create a comma-separated file `.inputs`, containing the
locations of input files and the URLs pointing to them, in the first and second
field, respectively. Additionally, the file needs to include one row, in which
the first field is `workflow` (case-sensitive!). This file will be used as an
input to the example CWL workflow in the last part. You can use the following
command to create such a file, but make sure to replace the example contents.
Also make sure not to include commas in the file location field.

```bash
cat << "EOF" > .inputs
location_x,https://link.to.some/file.txt
location_y,https://link.to.some/other_file.tab
location_z,https://link.to.some/third_file.png
workflow,https://link.to.some/workflow_input
```

Finally, you will need to create a secrets file `.env` with the following
command.  You can either set the environment variables in your shell or set the
actual values in the command below. Either way, you need to create the file, it
is not sufficient to just the environment variables in your shell!

```bash
cat << EOF > .env
FUNNEL_SERVER_USER=$FUNNEL_SERVER_USER
FUNNEL_SERVER_PASSWORD=$FUNNEL_SERVER_PASSWORD
TES_GATEWAY=$TES_GATEWAY
EOF
```

> If you want to run the demo on the ELIXIR Cloud infrastructure, please
> contact Alex Kanitz who can share the TES instances and secrets with you.

## Start notebook server

Start the Jupiter notebook server with the following command:

```bash
jupyter-lab demo.ipynb
```

Alternatively, run the demo via Jupyter Notebook or via your shell terminal.

[demo-cwl]: <https://github.com/elixir-cloud-aai/elixir-cloud-demos/tree/main/demos/2023-ecp-f2f>
[docs-jupyter-lab]: <https://jupyterlab.readthedocs.io/>
[lang-cwl]: <https://www.commonwl.org/>
[lang-smk]: <https://snakemake.readthedocs.io/>
[soft-conda]: <https://conda.io/>
[soft-curl]: <https://curl.se/>
[soft-funnel]: <https://ohsu-comp-bio.github.io/funnel>
[soft-jupyter]: <https://jupyter.org/>
[soft-kube]: <https://kubernetes.io/>
[soft-mamba]: <https://mamba.readthedocs.io/>
[soft-protes]: <https://github.com/elixir-cloud-aai/proTES>
[soft-py-tes]: <https://github.com/ohsu-comp-bio/py-tes>
[soft-tesk]: <https://github.com/elixir-cloud-aai/tesk>
[specs-tes]: <https://github.com/ga4gh/task-execution-schemas/>
