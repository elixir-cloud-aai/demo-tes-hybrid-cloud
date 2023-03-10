# demo-tes-hybrid-cloud

## Objectives

Demonstrate workflow execution via the GA4GH TES backend of the Snakemake TES workflow engine.

##
NOTE: Tutorial and Information was adapted/copied from [CWL Demo][tut-cwl]

## Service requirements

The following services were already deployed by ELIXIR for the demo:

| Service | Service Type |Version / Image | Configuration | Comment |
| --- | --- | --- | --- | --- |
| [TESK][soft-tesk] | TES instance | `cerit.io/tes-wes/tesk-api:0.1` | Authorization checks disabled; RW permissions for FTP preconfigured | Deployments for Kubernetes and OpenShift |
| [Funnel][soft-funnel] | TES instance | `0.10.1` (OpenPBS) / commit `#52ef90f` (Slurm) | Basic authentication; FTP access via basaic auth credentials in FTP URLs | Deployments for OpenPBS and Slurm; others possible |
| [proTES][soft-protes] | TES clienet & instance | `elixircloud/protes:20230218` | Authorization checks disabled; all TESK and Funnel instances need to be listed in `tes.service_list` in the app configuration prior to | 
| [vsftpd][soft-vsftpd] | FTP server |`3.0.2-29.el7_9.x86_64` on Rocky Linux 8 | Basic authentication | Deployments at multiple locations can be used for reading inputs, but not writing outputs, as long as access credentials are set in TESK instances _and_ basic authentication credentials are passed as part of the FTP URLs to Funnel |

## Client requirements

You can install all client requirements with Conda or Mamba:
```bash
conda env install -n demo-2023-ecp-f2f -f environment.yml

mamba env install -n demo-2023-ecp-f2f -f environment.yml
```

Install a specific version of py-tes from a specific commit on a fork:

```bash
pip uninstall py-tes
pip install git+https://github.com/ohsu-comp-bio/py-tes.git@a9ac2959fdb38bd31433d358724e20c2c544c6a1
```

Verify the successful installation:

```bash
curl --version
cwl-tes --version
jq --version
jupyter --version
jupyter-lab --version
snakemake --version
```

Next, you need to create a listing of the available TES instances in a
comma-seprated file `.tes_instances`. Two fields/columns are required, a
description of the TES instance, and the URL pointing to it. You can use the
following command to create such a file, but make sure to replace the example
contents and do not use commas in the name/description field:

```bash
cat << "EOF" > .tes_instances
Funnel/Slurm @ YourNode,https://tes.your-node.org/
Funnel/PBS @ YetAnotherNode,https://tes.yet-another-node.org/
TESK/Kubernetes @ OtherNode,https://tes.other-node.org/
EOF
```

> Note that due to some differences between TESK and Funnel in handling FTP
> files, it is important that any Funnel service contains the substring
> `Funnel`(case-sensitive!) in its name/description, as in the example content.
> Otherwise, some of the demo tasks will not work for Funnel services!

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
FTP_USER=$FTP_USER
FTP_PASSWORD=$FTP_PASSWORD
FUNNEL_SERVER_USER=$FUNNEL_SERVER_USER
FUNNEL_SERVER_PASSWORD=$FUNNEL_SERVER_PASSWORD
TES_GATEWAY=$TES_GATEWAY
FTP_INSTANCE=$FTP_INSTANCE
EOF
```

> If you want to run the demo on the ELIXIR Cloud infrastructure, please
> contact Alex Kanitz who can share the TES instances and secrets with you.

## Start notebook server

Start the Jupiter notebook server with the following command:

```bash
jupyter-lab snakemake_demo.ipynb
```
Akternatively run the demo via Jupiter notebook or via your shell terminal.


[docs-jupyter-lab]: <https://jupyterlab.readthedocs.io/>
[lang-cwl]: <https://www.commonwl.org/>
[lang-smk]: <https://snakemake.readthedocs.io/>
[specs-tes]: <https://github.com/ga4gh/task-execution-schemas/>
[soft-conda]: <https://conda.io/>
[soft-curl]: <https://curl.se/>
[soft-cwl-tes]: <https://github.com/ohsu-comp-bio/cwl-tes>
[soft-vsftpd]: <https://security.appspot.com/vsftpd.html>
[soft-jupyter]: <https://jupyter.org/>
[soft-kube]: <https://kubernetes.io/>
[soft-funnel]: <https://ohsu-comp-bio.github.io/funnel>
[soft-mamba]: <https://mamba.readthedocs.io/>
[soft-protes]: <https://github.com/elixir-cloud-aai/proTES>
[soft-py-tes]: <https://github.com/ohsu-comp-bio/py-tes>
[soft-tesk]: <https://github.com/elixir-cloud-aai/tesk>
[tut-cwl]: <https://github.com/elixir-cloud-aai/elixir-cloud-demos/tree/main/demos/2023-ecp-f2f>
