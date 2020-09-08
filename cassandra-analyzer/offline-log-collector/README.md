# Offline Log Collection for Cassandra
## What is "offline log analysis"?
Sometimes it is preferable to do "online log analysis", which is where you collect logs on a live cluster and ingest into Elasticsearch/Kibana (or some other dashboard). However, there are situations where this is not possible or preferable and you want to grab some logs, put them in a tarball, and ingest into your dashboard, often running in a separate host. We call this "offline log analysis". 

First, you will need to collect your logs and grab other diagnostic data from your Cassandra nodes. That is what this tool is for.

## Setup
- Requires python3 and pip3

### Configuration
- Create a config/environments.yaml
    Should be same format as TableAnalyzer takes
    ```
    cp config-templates/environments-sample.yaml config/environments.yaml
    vim config/environments.yaml
    # ...
    ```

    See below for what options to set here.

- Create a config/settings.yaml
    ```
    cp config-templates/settings.sample.yaml config/settings.yaml
    vim config/environments.yaml
    # ...
    ```
    See below for what options to set here.

### Run it
- Then just run this:
```
  pip3 install -r requirements.txt
  python3 collect_logs.py <client_name>
```

You should now have a tarball in `log-tarballs-to-ingest/<client_name>_<timestamp>.tar.gz`

It is ready to ingest using `ingest_tarball.py <client_name>_<timestamp>.tar.gz <client_name>` (and whatever flags you want to send in, see below for instructions on ingest_tarball.py)

## environments.yaml

Follows same format as environments.yaml for TableAnalyzer. 

## settings.yaml

### Options for cluster_settings
- node_defaults: can set anything that can be set for settings_by_node (see below), and will be applied for any node that does not have that setting set under settings_by_node.

### Options for settings_by_node
- nodetool_cmd: what command to use to run nodetool. Defaults to `nodetool` (which works for a package installation). For tarball installation, you can use `<path to tarball>/bin/nodetool` for example
- JMX_PORT: jmx port used by this node

## Testing
- These are not unit tests per se, but just wrapper around the actual script that sets up a test env first.
- Requires python3 and pip3
- Then just run this
```
  pip3 install -r requirements.txt
  pip3 install -r test/requirements.txt
  cd test
  python3 collect_logs_test.py
```

### Debugging Tests
- If you get error `File exists: '$HOME/.ccm/test_cluster'`: 
    The test did not clean up correctly from last time (`test_cluster` is the name of the cluster we use for testing with ccm). The test script might have already removed the `test_cluster` for you, and you can just run the test again and it should work. If not though, and **ASSUMING YOU DON'T NEED THAT CLUSTER ANYMORE:** Remove the old cluster so you can run test again: 
    ```
    ccm test_client remove

    # now run the test again
    python3 collect_logs_test.py
    ```

## SSH support
Running collect_logs.ph using SSH is currently not supported, though it is on our to-do list. In the meantime, you can run the script within separate nodes and combine using the instructions below.

## Combining tarballs
Sometimes it is necessary to combine several tarballs together.
See [here](https://superuser.com/a/1122546/654260) for how this works.

cat tar2.tgz tar1.tgz > combined.tgz

When ingesting though, make sure to add the `--ignore-zeros` flag, e.g., 
```bash
    python3 ingest_tarball.py my-client-logs-tarball.tar.gz my_client --ignore-zeros
```

### Current Assumptions
- even after concatenating together two tarballs, the final tarball should only have a single root directory. This means that the original directories that were gzipped need to have the same name originally
- hostnames need to be unique per node. I.e., if hostname -i for each node returns `127.0.0.1` (or anything that will overlap with another node's hostname), then you will have to rename these directories manually before combining. If you don't, logs for one node will overwrite logs for previous nodes that had the same hostname

### Example: 
An example of using tarball concatenation with this tool can be found at: `test/test-tarball-concatenation.sh`


## Development
### Adding more logs to our tarball
If you want to add more logs from the Cassandra node into the tarball for ingestion:

1) Add another command to `NodeAnalyzer/nodetool.receive.v2.sh` 
  - `collect_logs.py` calls `NodeAnalyzer/nodetool.receive.v2.sh` on each node to get logs and conf files and nodetool output. So to add more files to that list, edit `NodeAnalyzer/nodetool.receive.v2.sh`.
  - Make sure to make a directory for it too e.g., something like:
      ```
      mkdir -p $data_dest_path/<your new path>
      ```

2) If `nodetool.receive.v2.sh` doesn't place the files into a directory that already gets copied, you will have to edit `helper_classes/node.py`
  - `collect_logs.py` will call `helper_classes/node.py` when it is creating the tarball.
  - See `helper_classes/node.py#copy_files_to_final_destination`, which copies all the files for a given node and creates directories in the destination directory if necessary.
  - The files you want copied need to be copied in the `node.py#copy_files_to_final_destination` method, or they will not end up in the tarball at the end.

3) Edit `ingest_tarball.py` to ingest these new files that you want added into Kibana
  - If these are log files that you are adding, Kibana won't see them unless you configure our ingestion tool to do so.
  - `ingest_tarball.py` actually looks at `helper_classes/filebeat_yml.py#log_type_definitions` for what will end up in your filebeat.yml, as well as for what to ingest into kibana. Add a new item in that list in order to ingest your new logs.
      * key (e.g., "spark.master") can be anything as long as it's unique, it is more of a label for us really.
      * `path_to_logs_source` is where the log collection needs to put these logs (corresponds to what you set in `node.py#copy_files_to_final_destination`). These do not need to be unique: e.g., `cassandra.dse-collectd` and `cassandra.garbage_collection` have the same `path_to_logs_source`, and it's no problem. It just means our script will try to copy all these logs twice, which doesn't hurt anything, but it will have two separate entries in our generated filebeat.yml with different paths and different tags, which is what we need.
      * `path_to_logs_dest` is where the log collection will end up after unarchiving and positioning the logs. These do not need to be unique either.
      * `tags` is for separating these logs from other logs, so they are searchable in Kibana. 
      * `log_regex` is the regex that filebeat.yml will use to find htese logs after they are placed by the ingest_tarball.py script. Will include the `path_to_logs_dest` but the regex should include all files you are copying in and exclude files you don't want filebeat to ingest. Files that match will be assigned the `tags` in Kibana. Should be unique as well.
      * if any of the defaults (see 'filebeat_input_template') need to be overwritten, add a key "custom_overwrites" (see `linux.system` logs for example, which uses this).

4) If these are logs that have a pattern different from the other logs that we are ingesting into kibana, you will have to add the pattern into our `config-templates/filebeat.template.yml` file, under the field `processors`.
  - This file contains all dissect patterns.
  - You will probably want to add at least two patterns: 1. for the log pattern itself; 2. One for field: "log.file.path" so that these new logs' filepath gets into kibana correctly also
