#!/bin/bash

#Load properties file to get config values
DIR="$( cd "$( dirname "$0" )" && pwd )"
properties=$DIR/properties.yaml
source $properties

#Load defaults file
source /etc/default/dse

#Get primary IP of host
hostname=`/usr/sbin/ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'`
#echo $hostname
#Get DC Name of node
node_dc=`nodetool info | grep "Data Center" | xargs | awk '{print $4}'`

#Empty log file
#truncate -s 0 $log_file

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

#spark-scala calculation check
spark_calc_check()
{
    calc_raw=tmp/calc_raw.txt
    cat spark.scala | dse spark > $calc_raw 2>&1

    count=`cat tmp/calc_raw.txt | grep "approx_count_distinct: 6" | wc -l`
      if [ "$count" == "1" ]; then
        info_logging "- sparkscala - calculation check succeeded"
      else
        error_logging "- sparkscala - calculation check failed"
      fi
}

spark_calc_check
