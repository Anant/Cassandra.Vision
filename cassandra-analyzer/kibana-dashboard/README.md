# Kibana Dashboard
An importable kibana dashboard to use that's compatible with our filebeat setup. Built in Kibana 7.8.

## Description 
This Kibana dashboard provides several standard KQL/Lucene queries ready to go, some timelion charts, log counts etc, so that all the user has to do is import the kibana dashboard config from our repo. 

This will make our log analysis process even faster, helping us deliver analyses to clients in a more timely manner while keeping costs low. This also helps make our analysis more consistent, removing likelihood of using improper or misleading queries as well as potentially helping us write reports that have more consistent charts to our clients.

## Instructions
### Setup
- If you haven't already, install kibana, filebeat etc, and ingest logs into Kibana using filebeat. This dashboard will work best if you use the filebeat.yml that is generated by our python script.
- Import the Dashboard
- Change the time filters to match these particular logs

### Interpreting the pre-defined visualizations

Currently we have some timelion charts with corresponding data tables next to them. 

Note that the data tables sometimes have extra filters that the timelion to its left does not have. E.g., sometimes a table has an extra filter that only shows loglevel ERROR logs, whereas the timelion to its left doesn't. 

Be careful to read the labels and look at the source queries if you are not sure.

### Interacting with the Dashboard

Sometimes the dashboard might give more information than you need. You can of course edit each visualization yourself by clicking on "Edit" and then going to a specific visualization and modifying it to your likeing.

However, you can also hide certain logs by clicking on their labels to quickly remove extra noise.


### Use Our Pre-Defined Queries

We also have some predefined queries that you can use in order to find out more details about the actual logs. 
- Go to the "Discover" view and click on the dropdown that looks like a floppy disk. You can see some sample queries to get you started.
- Alternatively, if you look at the source filters/queries for the timelion charts or the data tables in the dashboard, that might also give you some ideas of queries to use in Discover.


## Development

### Add a new visualization
- Don't save the time filters. This way, the time filter will only be set by the dashboard, not the visualization.
- Probably do save the filters, assuming that the filter is an important part of the visualization.

### Export saved dashboards, queries, and visualizations
#### Using Kibana GUI
https://www.elastic.co/guide/en/kibana/7.8/managing-saved-objects.html#managing-saved-objects-export-objects
Our Dashboard is Called "Cassandra Logs Dashboard", and we have some queries namespaced with the word "Cassandra" as well so search for "Cassandra" in the saved objects search bar to find our dashboard and queries. Make sure to save all related objects.

#### Using API
(Have not tried yet)
https://www.elastic.co/guide/en/kibana/7.8/saved-objects-api-export.html#ssaved-objects-api-create-example

## Contributing
Please let us know if you have any other ideas of helpful visualizations, and feel free to make a PR as well!