# Contributing
Instructions for contributing to cassandra.vision is a work in progress. For the instructions that we do have, (or at least where we plan to put them once we write them) see links below.

## Development for offline-log-collector
[See here for instructions to add to offline-log-collector](../cassandra-analyzer/offline-log-collector/README.md#development).

## Development for offline-log-ingester
[See here for instructions to add to offline-log-ingester](../cassandra-analyzer/offline-log-ingester/README.md#development).

## Development for kibana-dashboard
[See here for instructions to add to kibana-dashboard](../cassandra-analyzer/kibana-dashboard/README.md#development).

## Development for elastic-kibana-ansible
[See here for instructions to add to elastic-kibana-ansible](../elastic-kibana-ansible/README.md#development).

# TODOs
This is for TODOs unrelated to any specific project. For individual projects TODO items, see individual notes on each separate project

- SPIKE Reorganize docs (?)
    * consider moving all docs into a centralized `docs` dir, like what we have in cassandra.toolkit
    * On the other hand, because each of these tools is a little bit more independent, we might want to keep them separate...need to consider if we plan on splitting apart TableAnalyzer and NodeAnalyzer into separte repo in the future. If so, maybe leave docs more or less as is. 
- SPIKE centralize `config`, `data`, `src` dirs as well?
    * same as above, it seems to depend on whether or not TableAnalyzer and NodeAnalyzer will be split off in the future.


