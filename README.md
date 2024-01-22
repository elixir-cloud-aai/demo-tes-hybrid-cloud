# Demonstrator: Hybrid Cloud via GA4GH TES

## Objectives

Demonstrate the federated execution of a Snakemake workflow across a network of compute
centers operationalized through the GA4GH TES API.

> **Note:** This demonstrator was adapted from an [earlier demonstrator][demo-cwl]
> focusing on the execution of a [CWL][lang-cwl] workflow.

## Service requirements

The following services were already deployed by ELIXIR for the demo:

| Service | Service Type | Version / Image | Configuration | Comment |
| --- | --- | --- | --- | --- |
| [TESK][soft-tesk] | TES | `cerit.io/tes-wes/tesk-api:0.1` | Authorization checks disabled | Deployments for Kubernetes and OpenShift |
| [Funnel][soft-funnel] | TES | `0.10.1` (OpenPBS) / commit `#52ef90f` (Slurm) | Basic authentication | Deployments for OpenPBS and Slurm; others possible |
| [proTES][soft-protes] | TES gateway | `elixircloud/protes:20230218` | Authorization checks disabled; all TESK and Funnel instances need to be listed in `tes.service_list` in the app configuration prior to executing the demo | &mdash; |
| [MinIO][soft-minio] | Storage (S3) | `RELEASE.2022-05-08T23-50-31Z` | Standard | Uses filesystem mode ([unsupported in newer versions][soft-minio-filesystem-mode]) |

## Client requirements

You can install the demo requirements with Conda or Mamba:

```bash
conda env install -n demo-tes-hybrid-cloud -f environment.yml
# or
mamba env install -n demo-tes-hybrid-cloud -f environment.yml
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

## Create configuration files

The demonstrator is set up in a way that it can be run on, in principle, on any
Funnel/TESK TES network and on any input files. Therefore, we first need to create a
couple of configuration files that represent _your_ specific setup.

### TES instances

First, you need to create a listing of the available TES instances in a comma-separated
file `.tes_instances`. Two fields/columns are required, a description of the TES
TES instance, and the URL pointing to it.

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

### Workflow inputs

You will also need to create a comma-separated file `.inputs`, containing the locations
of input files and the URLs pointing to them, in the first and second field,
respectively. Additionally, the file needs to include one row, in which the first field
is `workflow` (case-sensitive!). This file will be used as an input to the example CWL
workflow in the last part. You can use the following command to create such a file, but
make sure to replace the example contents.  Also make sure not to include commas in the
file location field.

```bash
cat << "EOF" > .inputs
location_x,https://link.to.some/file.txt
location_y,https://link.to.some/other_file.tab
location_z,https://link.to.some/third_file.png
workflow,https://link.to.some/workflow_input
```

### Credentials

Finally, you will need to create a secrets file `.env` with the following command. You
can either set the environment variables in your shell or set the actual values in the
command below. Either way, you need to create the file, it is not sufficient to just the
environment variables in your shell!

```bash
cat << EOF > .env
FUNNEL_SERVER_USER=$FUNNEL_SERVER_USER
FUNNEL_SERVER_PASSWORD=$FUNNEL_SERVER_PASSWORD
TES_GATEWAY=$TES_GATEWAY
EOF
```

## Start notebook server

Start the Jupiter notebook server with the following command:

```bash
jupyter-lab demo.ipynb
```

Alternatively, run the demo via Jupyter Notebook or via your shell terminal.

## Contact

For questions and inquiries, please contact <cloud-service@elixir-europe.org>. You can
also reach out to us if you would like to execute the demonstrator on the ELIXIR Cloud
infrastructure.

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
[soft-minio]: <https://min.io/>
[soft-minio-filesystem-mode]: <https://min.io/docs/minio/linux/operations/install-deploy-manage/migrate-fs-gateway.html>
[soft-protes]: <https://github.com/elixir-cloud-aai/proTES>
[soft-py-tes]: <https://github.com/ohsu-comp-bio/py-tes>
[soft-tesk]: <https://github.com/elixir-cloud-aai/tesk>
[specs-tes]: <https://github.com/ga4gh/task-execution-schemas/>