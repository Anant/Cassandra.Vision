### Example error messages 
#### FileNotFoundError: ...nodes/nodes
```
FileNotFoundError: [Errno 2] No such file or directory: '.../cassandra.vision/cassandra-analyzer/offline-log-ingester/logs-for-client/<client-name>/incident-<incident-id>/tmp/nodes/nodes'
```
This means that the ingested tarball looked something like this: 
```
<tarball-filename>.tar.gz OR <tarball-filename>.zip
        nodes/
            <ip-1>/
            ...
```
The tarball is missing the `<archived-dir>/`, so our script thinks that `nodes` is the name of the `<archived-dir>/`. Consequently, it's looking for `nodes/nodes/` but can't find it. 

To solve, put the `nodes` dir inside a parent directory, rezip your tarball and try again.



### Solutions
- reformat your tarball and zip it back up, and run script again
- Do dangerous stuff if you are feeling confident that you know what you're doing, like going into the `./logs-for-client/` dir where the unzipped logs get put into, and rearrange things there, and temporarily commenting out steps in the `run` method of the `ingest_tarball.py` script, particularly `self.extract_tarball()`, then running `ingest_tarball.py` again. Obviously less than ideal.

## Debugging
### Debugging the filebeat generator
  - Try editing the filebeat.yml manually and running again 
      See [instructions here](#want-to-add-some-logs-and-run-script-again-with-the-same-config) for running again and for where the generated filebeat.yaml is.

#### ERROR: failed to open store 'filebeat': open /var/lib/filebeat/registry/filebeat/meta.json: no such file or directory
This seems to be because newer versions of ES/filebeat (e.g., 7.9.x) have different behavior, and to clear out the registry you actually need to remove the whole `/var/lib/filebeat/registry`, not just the subdirectory `/var/lib/filebeat/registry/filebeat`, which worked before. 

If you don't delete the `/var/lib/filebeat/registry` directory, filebeat doesn't seem to know that it needs to regenerate that directory for you, and throws that error.

Solution: `rm -rf /var/lib/filebeat/registry`

For reference, see [here](https://discuss.elastic.co/t/cant-start-filebeat/181050/7).

### Debugging ES
#### Try sudo filebeat setup
Sometimes filebeat will process logs correctly (which you will be able to see in the filebeat log output, since it will show a log (level DEBUG) for event "Publish event"that shows all the fields. However, it won't get into kibana correctly. Sometimes all it takes is running `sudo filebeat setup` so that filebeat configures for the current elasticsearch setup

Note that by default, `sudo filebeat setup` will use your default filebeat.yml file, which is found at `/etc/filebeat/filebeat.yml`. Make sure those settings are correct, since even running filebeat with a different filebeat.yml will not override some of these configs (especially configs under the `setup` property, e.g., `setup.template.settings`). Those settings only get set when running `filebeat setup`. 

If you want to setup filebeat using a different filebeat.yml file, you can use the `--c` flag, e.g.,:

```
sudo filebeat setup --c cassandra.vision/cassandra-analyzer/offline-log-ingester/logs-for-client/{client_name}/incident-{incident_id}/tmp/filebeat.yaml
```

#### Error: ConnectionError(('Connection aborted.', ConnectionResetError(104, 'Connection reset by peer')))
Your elasticsearch or kibana hosts might need to be set if you get an error that looks like the following after running the script:
```
elasticsearch.exceptions.ConnectionError: ConnectionError(('Connection aborted.', ConnectionResetError(104, 'Connection reset by peer'))) caused by: ProtocolError(('Connection aborted.', ConnectionResetError(104, 'Connection reset by peer')))
```

You can find instructions for doing that above under [Specifying Kibana endpoint](#Specifying Kibana endpoint).

ES host can be set using --es-hosts flag as well.

#### Error: 
```
Elasticsearch.exceptions.ConnectionError: ConnectionError(<urllib3.connection.HTTPConnection object at 0x7fab672f0780>: Failed to establish a new connection: [Errno 111] Connection refused) caused by: NewConnectionError(<urllib3.connection.HTTPConnection object at 0x7fab672f0780>: Failed to establish a new connection: [Errno 111] Connection refused)
```

Diagnosing this one:
- There's probably also something like this in the stacktrace:
```
...
File "ingest_tarball.py", line 275, in clear_filebeat_indices_and_registry
self.es.indices.delete(index='filebeat-*')
...
```

- Also you are probably using `--clean-out-filebeat-first` flag, since this is the only thing we're using the python client for right now.

Solution: 
ES Python client isn't connecting to elasticsearch. You probably need to set the --es-hosts flag to something else.

#### ERROR: sudo: filebeat: command not found
E.g., 
```
=== Running Filebeat ===
Running filebeat command: sudo filebeat -e -d "*" --c /home/ryan/projects/cassandra.vision/cassandra-analyzer/offline-log-ingester/logs-for-client/test_client/incident-1620704941.7606971/tmp/filebeat.yaml
sudo: filebeat: command not found
```

Solution:
You need to have filebeat installed on your system. [Follow instructions here](./README.md#step-10-prerequisites).