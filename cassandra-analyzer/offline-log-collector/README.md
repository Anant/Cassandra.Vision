# Offline Log Collection for Cassandra
![](https://github.com/Anant/cassandra.vision/raw/master/docs/assets/diagrams/cassandra.vision.architecture-offline-log-collector.png)

Offline Log Analysis begins with offline log collection. That is what this tool is for.

Note that in general, if you are using DSE, you will probably just want to use the Datastax opscenter diagnostic tarball instead. However, if you are using open source Apache Cassandra, you can use this tool instead.

This tool also executes commands from TableAnalyzer and NodeAnalyzer. Note though that it only runs the TableAnalyzer `receive` command, it does not transform the cfstats/tablestats into a CSV or convert it to a formatted spreadsheet. That will need to be performed separately, but these instructions will guide you through that process as well.

### Table of Contents
- [Step #1: Setup](#Step-1-setup)
    - [Step #1.0: Prerequisites](#Step-10-prerequisites)
    - [Step #1.1: Install Requirements](#Step-11-install-requirements)
    - [Step #1.2: Configuration](#Step-12-configuration)
        - [Step #1.2.1: Create a `config/environments.yaml` File](#Step-121-Create-a-configenvironmentsyaml-File)
        - [Step #1.2.2: Create a `config/settings.yaml` File](#Step-122-Create-a-configsettingsyaml-File)
- [Step #2: Run it](#Step-2-run-it)
- [Testing](#testing)
- [Development](#development)
- [TODOs/Project Backlog](#todosproject-backlog)

# Step #1: Setup
## Step #1.0: Prerequisites
- Requires python3 and pip3
-  Currently also requires `nodetool` to be callable from the commandline on the node(s) that logs are collected from.

## Step #1.1: Install Requirements
You will need to install requirements for both offline-log-collector and TableAnalyzer.

```
pip3 install -r requirements.txt
pip3 install -r TableAnalyzer/requirements.txt
```

## Step #1.2: Configuration
### Step #1.2.1: Create a `config/environments.yaml` File

The `environments.yaml` file follows same format as environments.yaml for TableAnalyzer. [Click here for instructions on how to setup environments.yaml](./TableAnalyzer/README.md#set-configuration-create-environmentsyaml-file). 

```
cp config-templates/environments-sample.yaml config/environments.yaml
vim config/environments.yaml
# ...
```

#### SSH support (TODO)
For now, running `collect_logs.py` using SSH is currently not supported. If you need SSH support, you can use NodeAnalyzer or TableAnalyzer, but not by using collect_logs.py.

However, SSH support it is on our to-do list and we hope to add it is soon. In the meantime, you can run the script within separate nodes and combine using the [instructions for combining tarballs](#combining-tarballs) below.

#### Combining tarballs
Sometimes it is necessary to combine several tarballs together, in particular when you want to run `offline-log-collector` on multiple nodes and combine them together.

See [here](https://superuser.com/a/1122546/654260) for how this works. The basic idea is that you `cat` two files into a combined file. For example:

```
cat tar2.tgz tar1.tgz > combined.tgz
```
- Combined Tarball Example
    - An example of using tarball concatenation with this tool can be found (and tested) at: `test/test-tarball-concatenation.sh`

- Ingesting a combined tarball
    - When ingesting a combined tarball, make sure to add the `--ignore-zeros` flag, e.g., 
        ```bash
            python3 ingest_tarball.py my-client-logs-tarball.tar.gz my_client --ignore-zeros
        ```

- Current Assumptions/Requirements
    - Even after concatenating together two tarballs, the final tarball should only have a single root directory. 
        - This means that the original directories that were gzipped need to have the same name originally
    - Hostnames need to be unique per node. 
        - I.e., if hostname -i for each node returns `127.0.0.1` (or anything that will overlap with another node's hostname), then you will have to rename these directories manually before combining. 
        - If you don't, logs for one node will overwrite logs for previous nodes that had the same hostname within the combined tarball.

#### Step #1.2.2: Create a `config/settings.yaml` File
First, copy the example `settings.yaml` file to get you started. Note that the script is going to look for the `settings.yaml` file at `./config/settings.yaml`.
    ```
    cp config-templates/settings.sample.yaml config/settings.yaml
    vim config/settings.yaml
    # ...
    ```

Then, change what you need to in the `settings.yaml` file. Here are the descriptions of what you need to set:

- Options for `cluster_settings`
    - `node_defaults`: As the name implies, these are the defaults. This can set anything that can be set for `settings_by_node` (see below), and will be applied for any node that does not have that setting set under `settings_by_node`.

- Options for `settings_by_node`
    - `nodetool_cmd`: What command to use to run nodetool. Defaults to `nodetool` (which works for a package installation). For tarball installation, you can use `<path to tarball>/bin/nodetool` for example
    - `JMX_PORT`: jmx port used by this node.

# Step #2: Run it
- Determine what args you need to set according to the [chart below](#execution-options).
- Then just run this:
```
  pip3 install -r requirements.txt
  python3 collect_logs.py <client_name>
```

You should now have a tarball in `cassandra-analyzer/offline-log-ingester/log-tarballs-to-ingest/<client_name>_<timestamp>.tar.gz`. (Unless of course you specify a different tarball name in the options).

TableAnalyzer will also create a file in `data/<region>/<environment>/` for each node, called "<ip_addr>.txt" (e.g., 1.2.3.4.txt).

### Execution Options
In case you need to set some options, several arguments are available to you.

| Argument | Description | Default | Example |
| -------- | ----------- | ------- | ------- |
| `--tarball-filename` | The name that you want for the generated archive file. | `<client_name>_<timestamp>.tar.gz` | `python3 collect_logs.py <client_name> --tarball-filename custom-tarball-name.tar.gz` |
| `--cleanup-on-finish` | If the python script runs successfully, clears out all generated files that were created except for the new tarball. | `False` | `python3 collect_logs.py <client_name> --cleanup-on-finish` |
| `--settings-file` | Path to settings file | `cassandra-analyzer/offline-log-ingester/config/settings.yaml` | `python3 collect_logs.py <client_name> --settings-file ./custom-path/to/settings.yaml` |
| `--environment-file` | Path to environment yaml file | `cassandra-analyzer/offline-log-ingester/config/environments.yaml` | `python3 collect_logs.py <client_name> --settings-file ./custom-path/to/environments.yaml` |
| `--skip-table-analyzer` | If set, will not run TableAnalyzer | `False` | `python3 collect_logs.py <client_name> --skip-table-analyzer` |
| `--skip-node-analyzer` | If set, will not run NodeAnalyzer | `False` | `python3 collect_logs.py <client_name> --skip-node-analyzer` |

### What's next
Now that you have a tarball with your node's logs, as well as `cfstats`/`tablestats` output, you are ready to ingest your log files into Elasticsearch/Kibana and generate a spreadsheet using TableAnalyzer. 

- [Click here to start ingesting your log files into Elasticsearch/Kibana](../offline-log-ingester/README.md)
- [Click here to start transforming your nodetool output into a formatted spreadsheet using TableAnalyzer](./TableAnalyzer/README.md#step-3-generate-spreadsheet)
  - Note that at this point, we have already ran the `cfstats.receive.py` script for you. Now all you will have to do is transform it into a CSV and then convert that into a spreadsheet, following instructions in the link above.

# Testing
[For instructions on testing, see notes here](./test/README.md).

# Development
TODO add instructions for developing offline-log-collector.

# TODOs/Project Backlog
- SSH Support, for remote execution on multiple nodes at once
- Unit tests
