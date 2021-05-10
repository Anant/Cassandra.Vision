# Offline Log Collection for Cassandra
## What is "offline log analysis"?
Sometimes it is preferable to do "online log analysis", which is where you collect logs on a live cluster and ingest into Elasticsearch/Kibana (or some other dashboard). However, there are situations where this is not possible or preferable and you want to grab some logs, put them in a tarball, and ingest into your dashboard, often running in a separate host. We call this "offline log analysis". 

First, you will need to collect your logs and grab other diagnostic data from your Cassandra nodes. That is what this tool is for.

## Setup
- Requires python3 and pip3
-  Currently also requires `nodetool` to be callable from the commandline on the node(s) that logs are collected from.

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

### What's next
Now that you have a tarball with metrics from nodetool and your Cassandra log files, you are now ready to either ingest your log files into Elasticsearch/Kibana and generating a spreadsheet using TableAnalyzer. 

- [Click here to start ingesting your log files into Elasticsearch/Kibana](../offline-log-ingester/README.md)
- [Click here to start transforming your nodetool output into a formatted spreadsheet using TableAnalyzer](./TableAnalyzer/README.md#generate-spreadsheet)
  - Note that at this point, we have already ran the `cfstats.receive.py` script for you. Now all you will have to do is transform it into a CSV and then convert that into a spreadsheet, following instructions in the link above.

# Instructions for YAML files

## environments.yaml

The environments.yaml file follows same format as environments.yaml for TableAnalyzer. [Click here for instructions on how to setup environments.yaml](./TableAnalyzer/README.md). 

## settings.yaml

### Options for cluster_settings
- node_defaults: can set anything that can be set for settings_by_node (see below), and will be applied for any node that does not have that setting set under settings_by_node.

### Options for settings_by_node
- nodetool_cmd: what command to use to run nodetool. Defaults to `nodetool` (which works for a package installation). For tarball installation, you can use `<path to tarball>/bin/nodetool` for example
- JMX_PORT: jmx port used by this node

## Testing
- These are not unit tests per se, but just wrapper around the actual script that sets up a test env first.
- Requires python3 and pip3
- Make sure no other cassandra instance is running on your localhost (or else ccm will conflict with those ports, e.g., `OSError: [Errno 98] Address already in use`)
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

