# cassandra.toolkit/NodeAnalyzer
A quick and dirty tool to grab all the information for a specific node and tarzip it into a ball. 

TODO: Later will be integrated better with how TableAnalyzer goes and gets all the data for a cluster. 

Please make sure you move the empty data/* directories if you move this script out. It uses a relative directory reference. 

![NodeAnalyzer Folders](./assets/NodeAnalyzer_folders.jpg)

## Usage
```
bash ./nodetool.receive.sh {logdirectory} {confdirectory} {datacentername} {0|1} (verbose)"
```

## Examples:

### Verbose output 

```
bash ./nodetool.receive.sh /var/log/cassandra /etc/cassandra DC1 1
```

### Silent output 

```
bash ./nodetool.receive.sh /var/log/cassandra /etc/cassandra DC1 0
```

## Implementation Notes:
- It uses `hostname -i` to get the IP address to name the tar.gz file

## Want to run other nodetool commands?
If you want, you can add other nodetool commands to nodetool.commands.txt

http://cassandra.apache.org/doc/latest/tools/nodetool/nodetool.html
