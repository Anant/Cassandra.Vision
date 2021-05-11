# Expected Tarball Format
A number of errors can occur if the tarball or zip file with the logs is not formatted exactly like tarballs received from opscenter or our [`offline-log-collector`](../offline-log-collector/README.md) tool. Here are some instructions to make sure your tarball will work in offline-log-ingester.

### Format: .tar.gz or .zip
Our tool, the offline-log-ingester, is made primarily to handle `.tar.gz` files, but also supports .zip files. 

If this is a .zip, the script will unarchive the archive still but will likely fail unless the directory layout is exactly what DSE opsecenter returns. 

### What we're expecting:
```
<tarball-filename>.tar.gz OR <tarball-filename>.zip
    <archived-dir>/ 
        nodes/
            <ip-1>/
                logs/
                    cassandra/
                        audit/audit.log (optional)
                        system.log
                        gremlin.log (optional)
                        debug.log (optional)
                        output.log (optional)
                        gc.log (optional)
                    spark/
                        master/
                            master.log
                        worker/
                            worker.log
            <ip-2>/
                … (same as ip-1)
            … (other ips)
```

### Notes:
- `<archived-dir>` (see above) is often the same name as `<tarball-filename>` but doesn't need to be.
- Files marked `(optional)` in the chart above:
    - The absence of optional files mentioned above won't stop the script from running to the end and ingesting whatever files are there, but the presence of those files means those files will be ingested too. 
    - See `./helper_classes/filebeat_yml.py` for what files the filebeat ingester is looking for. 
- All log files can either end in `.log` as above, or `.log*`. Often this looks something like `gc.log.0` or `gc.log.3.current`. All that end in `.log*` will be ingested. 
- Additional files besides what is referred to above won't have any affect whatsoever. 