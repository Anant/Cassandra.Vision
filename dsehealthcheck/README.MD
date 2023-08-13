# Healthcheck functions
- Cqlsh connectivity check:
    - Locally connects to cqlsh on the node using credentials and verifies if the connection is getting established.
- Nodetool status check:
    - Checks if all the nodes in the cluster are in UN state.
- Analytics master check:
    - Checks if the analytics service master is available for the node's Data Center.
- Solr check:
    - Checks if the connection to the solr service is working.
- Schema mismatch check:
    - Checks if the schema is in sync across all the nodes of the cluster.
- Pending compactions check:
    - Checks if the pending compaction count is above a certain threshold on each node of the cluster.
- Write latency check:
    - Checks if the write latency on nodetool proxyhistograms is within a certain threshold on each node of the cluster.
- Read latency check:
    - Checks if the read latency on nodetool proxyhistograms is within a certain threshold on each node of the cluster.
- Blocked tpstats check:
    - Checks if there are any blocked threads in nodetool tpstats.
- Pending tpstats check:
    - Checks if there are any pending threads in nodetool tpstats.
- Data space check:
    - Checks if there is enough disk space available on the data volume of the node.
- CPU utilization check:
    - Checks if the CPU utilization of each node is within a certain threshold.
- Free memory check:
    - Checks if there is enough free memory available on a node.
- Sparksql count check:
    - Verifies row count on a test table using sparksql to see if the service is working as expected.
- Sparksql join check:
    - Verifies sparksql service by performing a join on 2 test tables.
- Spark calc check:
    - Performs a basic count check to see if Spark service is working as expected.
- Tombstone check:
    - Checks if the tombstone count of each table is within a certain threshold on each node of the cluster.
- Partition size check:
    - Checks if the maximum partition size of each table is within a certain threshold on each node of the cluster.

# How to setup
- Get code using `git clone https://github.com/Anant/Cassandra.Vision.git`.
- Ensure that `net-tools` has been installed on the server as that is used for node IP collection. If not installed, you can install it using `sudo yum install net-tools -y`.
- Edit properties.yaml file and update settings like Cassandra username and password as required.
- Create schema in DSE by logging into cqlsh and then importing schema using `source 'schema.cql'`.
- Execute health check from command prompt using the command `./healthcheck.sh`.

# Note:
- This has been tested on DSE 6.8.23 running on a RHEL 9 server.