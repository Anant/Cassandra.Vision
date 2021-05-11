# Testing offline-log-ingester

# Instructions: 
### Prerequisites 
If you haven't already, run the test script for `offline-log-collector` first. [You can find instructions here](../../offline-log-collector/test/README.md).

You will also need to make sure you have all the prerequisites for running the main ingester script as [found here](../README.md#step-10-prerequisites).

### Install requirements
You will need to install all the requirements for running the main ingester script as [found here](../README.md#step-11-install-requirements).

### Run Integration test
Then run `ingest_tarball.py` on that test tarball:

```
# if at the `offline-log-collector/test` dir, first navigate to the offline-log-ingester dir
# cd ../../offline-log-ingester

# then run it
python3 ingest_tarball.py test_client.tar.gz test_client 
```

Or, if you are safe to wipe out the filebeat registry and filebeat indices before running the test:
```
# commented out since it is potentially destructive...and tests should generally not be destructive. But you can copy the command below if you're sure it's what you want.
# python3 ingest_tarball.py  test_client.tar.gz test_client --clean-out-filebeat-first
```

### OLD WAY: Use the test class
NOTE Currently out of date.

Old process was like this though:
```
  pip3 install -r requirements.txt
  pip3 install -r test/requirements.txt
  cd test
  python3 ingest_tarball_test.py
```

Will need to update `ingest_tarball_test.py` for this to work. Might not be worth supporting, just running the regular command on the test tarball is sufficient for now.

# Debugging Tests
For now, since the process is just using the main ingestion process on the test tarball, debugging the tests is the same process as normal [debugging for offline-log-ingester](./ingestion.debugging.md). 