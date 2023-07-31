# Healthcheck functions
- cqlsh connectivity check
- nodetool status check
- analytics master check
- solr check
- schema mismatch check
- pending compactions check
- write latency check
- read latency check
- blocked tpstats check
- pending tpstats check
- data space check
- cpu utilization check
- free memory check
- sparksql count check
- sparksql join check
- spark calc check
- tombstone check
- partition size check

# How to setup
- Get code using `git clone https://github.com/dipanshah/healthcheck.git`
- Edit properties.yaml file and update settings like Cassandra username and password as required
- Create schema in DSE by logging into cqlsh and then importing schema using `source 'schema.cql'`
- Execute health check from command prompt using the command `./healthcheck.sh`