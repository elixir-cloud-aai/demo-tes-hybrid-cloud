# Demonstrator: Hybrid Cloud via GA4GH TES

## Objectives

Demonstrate the federated execution of a Snakemake workflow across a network of compute
centers operationalized through the GA4GH TES API.

> **Note:** This demonstrator was adapted from an [earlier demonstrator][demo-cwl]
> focusing on the execution of a [CWL][lang-cwl] workflow.

## Service requirements

The demo needs the following services. The versions are those that the
[local setup](#try-it-out-locally) runs, and that the CI of this repository tests
the demo with:

| Service | Service Type | Version / Image | Configuration | Comment |
| --- | --- | --- | --- | --- |
| [Funnel][soft-funnel] | TES | `quay.io/ohsu-comp-bio/funnel:0.11.14` | Basic authentication | Deployments for Docker, OpenPBS, Slurm and others; all Funnel instances share one set of credentials (`FUNNEL_SERVER_USER`, `FUNNEL_SERVER_PASSWORD`) |
| [TESK][soft-tesk] | TES | &mdash; | Authorization checks disabled | Deployments for Kubernetes and OpenShift; not part of the local setup |
| [proTES][soft-protes] | TES gateway | `elixircloud/protes:0.6.0` | Access tokens of the users; all TES instances listed in `custom.tes.backends` of the app configuration (see [Configuration][protes-config]) | Routes each task to one of its TES instances at random; [routing by distance to the data][protes-distance] is an opt-in of the operator |
| S3 | Storage | Any S3 service | One bucket that the client and all TES instances can reach | The local setup uses [rclone][soft-rclone] (`rclone serve s3`) |

The demo was first run in 2023 on services deployed by ELIXIR, with TESK
(`cerit.io/tes-wes/tesk-api:0.1`), Funnel 0.10.1, proTES
`elixircloud/protes:20230218` and [MinIO][soft-minio]. Since proTES 0.3.0, the
gateway requires an access token for all task requests; since proTES 0.4.0, it lists
its TES instances in `custom.tes.backends` instead of `tes.service_list` (see the
[upgrade steps][protes-upgrading]).

## Client requirements

You need Git, and Conda or Mamba. Clone the repository and install the demo
requirements:

```bash
git clone https://github.com/elixir-cloud-aai/demo-tes-hybrid-cloud.git
cd demo-tes-hybrid-cloud
conda env create -n demo-tes-hybrid-cloud -f environment.yml
# or
mamba env create -n demo-tes-hybrid-cloud -f environment.yml
conda activate demo-tes-hybrid-cloud
```

The environment has Snakemake 7, whose option `--tes` runs the jobs of a workflow on a
TES instance (Snakemake 8 and later use the [TES executor plugin][soft-smk-tes]
instead), and [`py-tes`][soft-py-tes] 1.1.4 or later, which sends the access token
of `TES_TOKEN` to the gateway. Earlier `py-tes` commits (e.g., `5379b2a`) send Basic
credentials instead, which proTES doesn't accept.

Verify the successful installation:

```bash
curl --version
git --version
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
instance, and the URL pointing to it.

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

The workflow downloads one file from each of the URLs under `urls` in
`wf-federated/config.yaml`, in a task of its own, and writes the mean size of the
files to S3. You can replace them with the URLs of any small files that the TES
instances can reach. The jobs run in the image of Snakemake
(`snakemake/snakemake:v<version>`), whose certificate store dates from the release of
that version: check new URLs with `wget` in that image.

### Credentials

Finally, you will need to create a secrets file `.env` with the following command. You
can either set the environment variables in your shell or set the actual values in the
command below. Either way, you need to create the file, it is not sufficient to just
set the environment variables in your shell! The file holds passwords and a token:
never commit or share it, and make only you able to read it.

```bash
cat << EOF > .env
export FUNNEL_SERVER_USER=$FUNNEL_SERVER_USER
export FUNNEL_SERVER_PASSWORD=$FUNNEL_SERVER_PASSWORD
export TES_GATEWAY=$TES_GATEWAY
export TES_TOKEN=$TES_TOKEN
export ACCESS_KEY_ID=$ACCESS_KEY_ID
export SECRET_ACCESS_KEY=$SECRET_ACCESS_KEY
export ENDPOINT_URL=$ENDPOINT_URL
export BUCKET_PATH=$BUCKET_PATH
EOF
chmod 600 .env
```

| Variable | Value |
| --- | --- |
| `FUNNEL_SERVER_USER`, `FUNNEL_SERVER_PASSWORD` | The Basic credentials of the Funnel instances. |
| `TES_GATEWAY` | The base URL of the proTES gateway, e.g., `https://protes.example.org`. |
| `TES_TOKEN` | An access token for the proTES gateway. |
| `ACCESS_KEY_ID`, `SECRET_ACCESS_KEY` | The credentials of the S3 service. |
| `ENDPOINT_URL` | The URL of the S3 service. |
| `BUCKET_PATH` | The bucket, and optionally a path in it, for the results, e.g., `my-bucket/demo`. |

Snakemake passes the S3 settings (`--envvars`) to its jobs with each task, so the TES
instances and the gateway can read them: use credentials for the results bucket only.

## Start notebook server

Start the Jupiter notebook server with the following command:

```bash
jupyter-lab demo.ipynb
```

Alternatively, run the demo via Jupyter Notebook or via your shell terminal. The
notebook runs the workflow on each TES instance in turn, then through the gateway.
Before the run through the gateway, it unsets `FUNNEL_SERVER_USER` and
`FUNNEL_SERVER_PASSWORD`, as Snakemake would otherwise send them instead of the
access token.

## Try it out locally

The directory `local` has a setup of all services on one machine, with Docker Compose:
two Funnel instances, proTES in front of them with a fake identity provider, and an S3
service. It runs the notebook end to end with the Conda environment of
`environment.yml`, and checks the result in S3 and the tasks of the gateway. It needs
Docker with Compose, and access to the internet (for the images and the files of the
workflow):

```bash
docker compose -f local/compose.yaml run --build --rm demo
```

It ends with `PASSED: the demo ran end to end`. The executors of the tasks run as
containers on the host, through the Docker socket, and their work directories are
in `/tmp/demo-tes-hybrid-cloud`. All credentials of the setup are dummy values, and
the identity provider hands tokens to anyone: for local tests only. Remove the
setup afterwards:

```bash
docker compose -f local/compose.yaml down --volumes
docker run --rm -v /tmp:/host-tmp alpine rm -rf /host-tmp/demo-tes-hybrid-cloud
```

## Contact

For questions and inquiries, please contact <cloud-service@elixir-europe.org>. You can
also reach out to us if you would like to execute the demonstrator on the ELIXIR Cloud
infrastructure.

[demo-cwl]: <https://github.com/elixir-cloud-aai/elixir-cloud-demos/tree/main/demos/2023-ecp-f2f>
[lang-cwl]: <https://www.commonwl.org/>
[protes-config]: <https://protes.readthedocs.io/en/latest/configuration/>
[protes-distance]: <https://protes.readthedocs.io/en/latest/plugins/#routing-by-distance-to-the-data-opt-in>
[protes-upgrading]: <https://protes.readthedocs.io/en/latest/upgrading/>
[soft-funnel]: <https://ohsu-comp-bio.github.io/funnel>
[soft-minio]: <https://min.io/>
[soft-protes]: <https://github.com/elixir-cloud-aai/proTES>
[soft-py-tes]: <https://github.com/ohsu-comp-bio/py-tes>
[soft-rclone]: <https://rclone.org/commands/rclone_serve_s3/>
[soft-smk-tes]: <https://github.com/snakemake/snakemake-executor-plugin-tes>
[soft-tesk]: <https://github.com/elixir-cloud-aai/tesk>
