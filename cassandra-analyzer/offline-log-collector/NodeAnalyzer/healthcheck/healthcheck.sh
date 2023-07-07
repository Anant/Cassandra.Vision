#!/bin/bash

#Tested for DSE 6.8.23 on RHEL 9

#Load properties file to get config values
DIR="$( cd "$( dirname "$0" )" && pwd )"
properties=$DIR/properties.yaml
source $properties

#Load dse defaults file
source /etc/default/dse

#Temporary table list files
table_list=tmp/table_list.txt
table_filter=tmp/table_filter.txt

#Get primary IP of host
hostname=`/usr/sbin/ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'`
#echo $hostname
#Get DC Name of node
node_dc=`nodetool info | grep "Data Center" | xargs | awk '{print $4}'`

#Functions for logging
info_logging()
{
    echo "INFO $hostname `date +"%Y-%m-%d %H:%M:%S"` ${*}"
}

warn_logging()
{
    echo "WARN $hostname `date +"%Y-%m-%d %H:%M:%S"` ${*}"
}

error_logging()
{
    echo "ERROR $hostname `date +"%Y-%m-%d %H:%M:%S"` ${*}"
}

#Check for blocked counts in nodetool tpstats
blocked_tpstats_check()
{
    tpstats_raw=tmp/tpstats_raw.txt
    tpstats_filter=tmp/tpstats_filter.txt
    nodetool tpstats > $tpstats_raw
    awk '/CompactionExecutor/,/WRITE_SWITCH_FOR_MEMTABLE/' $tpstats_raw > $tpstats_filter

    while IFS= read -r line
    do
      tpstats_thread=`echo "$line" | awk '{print $1}' | xargs`
      blocked_tpstats_count=`echo "$line" | awk '{print $9}' | xargs`
      #echo $blocked_tpstats_count
      if [ "$blocked_tpstats_count" == "N/A" ]; then
        info_logging "- tpstats - 0 dropped messages for thread $tpstats_thread"
      elif [ "$blocked_tpstats_count" -gt "$blocked_thread_error" ]; then
        error_logging "- tpstats - $blocked_tpstats_count dropped messages for thread $tpstats_thread"
      elif [ "$blocked_tpstats_count" -gt "$blocked_thread_warn" ]; then
        warn_logging "- tpstats - $blocked_tpstats_count dropped messages for thread $tpstats_thread"
      else
        info_logging "- tpstats - $blocked_tpstats_count dropped messages for thread $tpstats_thread"
      fi
    done < "$tpstats_filter"
    
}

#Check for pending counts in nodetool tpstats
pending_tpstats_check()
{
    tpstats_raw=tmp/tpstats_raw.txt
    tpstats_filter=tmp/tpstats_filter.txt
    nodetool tpstats > $tpstats_raw
    awk '/CompactionExecutor/,/WRITE_SWITCH_FOR_MEMTABLE/' $tpstats_raw > $tpstats_filter

    while IFS= read -r line
    do
      tpstats_thread=`echo "$line" | awk '{print $1}' | xargs`
      pending_tpstats_count=`echo "$line" | awk '{print $3}' | xargs`
      #echo $pending_tpstats_count
      if [ "$pending_tpstats_count" == "N/A" ]; then
        info_logging "- tpstats - 0 pending messages for thread $tpstats_thread"
      elif [ "$pending_tpstats_count" -gt "$pending_thread_error" ]; then
        error_logging "- tpstats - $pending_tpstats_count pending messages for thread $tpstats_thread"
      elif [ "$pending_tpstats_count" -gt "$pending_thread_warn" ]; then
        warn_logging "- tpstats - $pending_tpstats_count pending messages for thread $tpstats_thread"
      else
        info_logging "- tpstats - $pending_tpstats_count pending messages for thread $tpstats_thread"
      fi
    done < "$tpstats_filter"

}

#Check output of nodetool status
nodetool_status_check()
{
    ip_count=`nodetool status | grep -E '\s[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\s' | wc -l`
    un_count=`nodetool status | grep -E '\s[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\s' | grep -E '^UN' | wc -l`
    if [ $ip_count != $un_count ]; then
      error_logging "- nodetool_status - Only $un_count nodes are up and normal"
    else
      info_logging "- nodetool_status - All $un_count nodes are up and normal"
    fi
}


#Check if analytics master is available in dsetool status
analytics_master_check()
{
    analytics_master=`dsetool status | grep $node_dc | awk '{print $9}' | xargs`
    if [[ $SPARK_ENABLED -eq 0 ]]; then
      info_logging "- spark - Spark is not enabled on node"
    elif [[ $SPARK_ENABLED -eq 1  && $analytics_master =~ [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3} ]]; then
      info_logging "- spark - Analytics master $analytics_master is available"
    else
      error_logging "- spark - Analytics master is not available"
    fi
}

#Check for schema mismatch by counting number of rows after schema version
schema_mismatch_check()
{
    schemacount=`nodetool describecluster | grep -A5 Schema | wc -l`
    #echo $schemacount
    if [ $schemacount -ne 3 ]; then
      error_logging "- schema_mismatch - Schema mismatch detected"
    else
      info_logging "- schema_mismatch - Schema is in sync"
    fi
}

#Check for pending compactions in nodetool compactionstats
pending_compactions_check()
{
    pending_compactions=`nodetool compactionstats | grep "pending tasks" | awk '{print $3}' | xargs`
    if [ "$pending_compactions" -gt "$pending_compactions_error" ]; then
      error_logging "- compactions - Pending compactions greater than $pending_compactions_error on node"
    elif [ "$pending_compactions" -gt "$pending_compactions_warn" ]; then
      warn_logging "- compactions - Pending compactions greater than $pending_compactions_warn on node"
    else
      info_logging "- compactions - Pending compactions under $pending_compactions_warn on node"
    fi
}

#Proxyhistograms write latency
write_latency_check()
{
    write_latency=`nodetool proxyhistograms | grep $percentile | awk '{print $3}' | xargs | cut -d. -f1`
    if [ "$write_latency" -gt "$write_latency_error" ]; then
      error_logging "- write_latency - $percentile percentile write latency $write_latency ms greater than $write_latency_error ms on node"
    elif [ "$write_latency" -gt "$write_latency_warn" ]; then
      warn_logging "- write_latency - $percentile percentile write latency $write_latency ms greater than $write_latency_warn ms on node"
    else
      info_logging "- write_latency - $percentile percentile write latency $write_latency ms less than $write_latency_warn ms on node"
    fi
}


#Proxyhistograms read latency
read_latency_check()
{
    read_latency=`nodetool proxyhistograms | grep $percentile | awk '{print $2}' | xargs | cut -d. -f1`
    if [ "$read_latency" -gt "$read_latency_error" ]; then
      error_logging "- read_latency - $percentile percentile read latency $read_latency ms greater than $read_latency_error ms on node"
    elif [ "$read_latency" -gt "$read_latency_warn" ]; then
      warn_logging "- read_latency - $percentile percentile read latency $read_latency ms greater than $read_latency_warn ms on node"
    else
      info_logging "- read_latency - $percentile percentile read latency $read_latency ms less than $read_latency_warn ms on node"
    fi
}

#Connect to cqlsh and get list of tables on cluster
cqlsh_check()
{
    #cqlsh -u $cqlsh_username -p $cqlsh_password -e "PAGING OFF;select keyspace_name, table_name from system_schema.tables" > $table_list #cqlsh connection with localhost
    cqlsh -u $cqlsh_username -p $cqlsh_password $hostname -e "PAGING OFF;select keyspace_name, table_name from system_schema.tables" > $table_list #cqlsh connection with IP
    if [ $? -eq 0 ]; then
        info_logging "- cqlsh - connected to cqlsh successfully"
    else
        error_logging "- cqlsh - cqlsh connection failed"
    fi

    #Remove headers and footers from table list
    head -n -2 $table_list | tail -n +5 | awk -F'|' '{gsub(/ /, "", $1); gsub(/ /, "", $2); print $1"."$2}' > $table_filter
}

#Get table tombstone count from nodetool tablestats
tombstone_check()
{
    while IFS= read -r line
    do
      tombstone_count=`nodetool tablestats $line | grep "Maximum tombstones per slice" | cut -f2 -d: | xargs`
      if [ "$tombstone_count" == "NaN" ]; then
        info_logging "- tablestats - 0 tombstones for table $line"
      elif [ "$tombstone_count" -gt "$tombstone_count_error" ]; then
        error_logging "- tablestats - $tombstone_count tombstones for table $line"
      elif [ "$tombstone_count" -gt "$tombstone_count_warn" ]; then
        warn_logging "- tablestats - $tombstone_count tombstones for table $line"
      else
        info_logging "- tablestats - $tombstone_count tombstones for table $line"
      fi
    done < "$table_filter"
}

#Get table partition size from nodetool tablestats
partition_size_check()
{
    while IFS= read -r line
    do
      partition_size=`nodetool tablestats $line | grep "Compacted partition maximum bytes" | cut -f2 -d: | xargs`
      if [ "$partition_size" -gt "$partition_size_error" ]; then
        error_logging "- tablestats - Max partition size $partition_size bytes for table $line"
      elif [ "$partition_size" -gt "$partition_size_warn" ]; then
        warn_logging "- tablestats - Max partition size $partition_size bytes for table $line"
      else
        info_logging "- tablestats - Max partition size $partition_size bytes for table $line"
      fi
    done < "$table_filter"
}

#Function that connects to solr http
solr_check()
{
    curl -s -o /dev/null http://$hostname:$solr_port/solr/
    if [ $? -eq 0 ]; then
        info_logging "- solr - connected to solr successfully"
    else
        error_logging "- solr - solr connection failed"
    fi
}

#Data directory free space check
data_space_check()
{
    data_dir=`cat $cassandra_yaml | grep -A5 'data_file_directories' | grep "     -" | cut -d- -f2 | xargs`
    #echo $data_dir
    dir_used=`df -h $data_dir | tail -n +2 | awk '{print $5}' | cut -d% -f1`
    #echo $dir_used
    if [ "$dir_used" -gt "$data_vol_free_space_error_threshold" ]; then
      error_logging "- disk_space - Data usage on volume $data_dir is $dir_used percent"
    elif [ "$dir_used" -gt "$data_vol_free_space_warn_threshold" ]; then
      warn_logging "- disk_space - Data usage on volume $data_dir is $dir_used percent"
    else
      info_logging "- disk_space - Data usage on volume $data_dir is $dir_used percent"
    fi
}

##Check CPU utilization
cpu_utilization_check()
{
    cpu_used=`top -n1 | grep "%Cpu(s)" | awk '{print $2}' | cut -d. -f1`
    if [ "$cpu_used" -gt "$cpu_use_error_threshold" ]; then
      error_logging "- cpu - CPU utilization of $cpu_used percent is greater than $cpu_use_error_threshold percent"
    elif [ "$cpu_used" -gt "$cpu_use_warn_threshold" ]; then
      warn_logging "- cpu - CPU utilization of $cpu_used percent is greater than $cpu_use_warn_threshold percent"
    else
      info_logging "- cpu - CPU utilization of $cpu_used percent is below $cpu_use_error_threshold percent"
    fi
}


##Check memory utilization
free_memory_check()
{
    free_memory=`free | grep Mem | awk '{print $7}' | xargs`
    if [ "$free_memory" -lt "$free_memory_error_threshold" ]; then
      error_logging "- memory - Free memory $free_memory KB is less than $free_memory_error_threshold KB"
    elif [ "$free_memory" -lt "$free_memory_warn_threshold" ]; then
      warn_logging "- memory - Free memory $free_memory KB is less than $free_memory_warn_threshold KB"
    else
      info_logging "- memory - Free memory $free_memory KB is more than $free_memory_error_threshold KB"
    fi
}

#Functions to execute
cqlsh_check
nodetool_status_check
analytics_master_check
solr_check
schema_mismatch_check
pending_compactions_check
write_latency_check
read_latency_check
blocked_tpstats_check
pending_tpstats_check
data_space_check
cpu_utilization_check
free_memory_check
tombstone_check
partition_size_check
