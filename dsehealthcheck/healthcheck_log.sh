#!/bin/bash

#Load properties file to get config values
DIR="$( cd "$( dirname "$0" )" && pwd )"
properties=$DIR/properties.yaml
source $properties
cassandra_log_path="/var/log/cassandra/"

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

#Function that reads system.log file to count errors, warnings and provide the top 5 most common errors
system_log_check()
{
    #system.log file
    system_log=$cassandra_log_path\system.log

    #Calculate time since this log file was created
    system_log_start_time=`head -1 $system_log | awk -F' ' '{print $3,$4}' | awk -F',' '{print $1}'`
    system_log_start_time_seconds=`date -d "$system_log_start_time" +%s`
    current_date=$(date +%s)
    system_log_difference=$((current_date - system_log_start_time_seconds))
    system_diff_hours=$(($system_log_difference / 3600))

    #Count errors and warnings in file
    system_error_count=0
    system_warn_count=0
    system_error_count=`grep ^ERROR $system_log | wc -l`
    system_warn_count=`grep ^WARN $system_log | wc -l`

    #Log information
    info_logging "- system.log - There are $system_error_count ERROR messages in $system_log in the last $system_diff_hours hour(s)"
    info_logging "- system.log - There are $system_warn_count WARN messages in $system_log in the last $system_diff_hours hour(s)"

    #Print top 5 most common error messages in file
    if [ $system_error_count -gt 0 ]; then
      system_log_error_raw=tmp/system_log_error_raw.txt
      grep ERROR $system_log | awk -F' - ' '{print $2}' | sort | uniq -c | sort -rn | head -5 > $system_log_error_raw
      while IFS= read -r line
      do
        count=`echo "$line" | awk '{print $1}'`
        message=`echo "$line" | awk '{$1=""; print $0}' | xargs`
        error_logging "- system.log - There are $count ERROR messages for '$message'"
      done < "$system_log_error_raw"
    else
      :
    fi

}

#Function that reads debug.log file to count errors, warnings and provide the top 5 most common errors
debug_log_check()
{
    #debug.log file
    debug_log=$cassandra_log_path\debug.log

    #Calculate time since this log file was created
    debug_log_start_time=`head -1 $debug_log | awk -F' ' '{print $3,$4}' | awk -F',' '{print $1}'`
    debug_log_start_time_seconds=`date -d "$debug_log_start_time" +%s`
    current_date=$(date +%s)
    debug_log_difference=$((current_date - debug_log_start_time_seconds))
    debug_diff_hours=$(($debug_log_difference / 3600))

    #Count errors and warnings in file
    debug_error_count=0
    debug_warn_count=0
    debug_error_count=`grep ^ERROR $debug_log | wc -l`
    debug_warn_count=`grep ^WARN $debug_log | wc -l`

    #Log information
    info_logging "- debug.log - There are $debug_error_count ERROR messages in $debug_log in the last $debug_diff_hours hour(s)"
    info_logging "- debug.log - There are $debug_warn_count WARN messages in $debug_log in the last $debug_diff_hours hour(s)"

    #Print top 5 most common error messages in file
    if [ $debug_error_count -gt 0 ]; then
      debug_log_error_raw=tmp/debug_log_error_raw.txt
      grep ERROR $debug_log | awk -F' - ' '{print $2}' | sort | uniq -c | sort -rn | head -5 > $debug_log_error_raw
      while IFS= read -r line
      do
        count=`echo "$line" | awk '{print $1}'`
        message=`echo "$line" | awk '{$1=""; print $0}' | xargs`
        error_logging "- debug.log - There are $count ERROR messages for '$message'"
      done < "$debug_log_error_raw"
    else
      :
    fi

}

#Function that reads sytem.log.*.zip files to count errors and warnings
system_zip_log_check()
{
    system_zip_file_list=tmp/system_zip_file_list.txt

    #Collect list of zip files
    ls $cassandra_log_path\system*zip > $system_zip_file_list 2>&-
    system_zip_count=`cat $system_zip_file_list | wc -l`

    system_zip_total_error_count=0
    system_zip_total_warn_count=0
    system_zip_log_earliest_time=$(date +%s)

    #Check if zip files exist or not. If yes, parse them.
    if [ $system_zip_count -gt 0 ]; then
      while IFS= read -r line
      do

        #Get start time of each file
        system_zip_log_start_time=`zcat $line | head -1 | awk -F' ' '{print $3,$4}' | awk -F',' '{print $1}'`
        system_zip_log_start_time_seconds=`date -d "$system_zip_log_start_time" +%s`

        #Calculate earliest time
        if [ $system_zip_log_start_time_seconds -lt $system_zip_log_earliest_time ]; then
          system_zip_log_earliest_time=$system_zip_log_start_time_seconds
        else
          :
        fi

        #Get ERROR and WARN count of each file
        system_zip_error_count=`zgrep ^ERROR $line | wc -l`
        system_zip_warn_count=`zgrep ^WARN $line | wc -l`

        system_zip_total_error_count=$(expr $system_zip_total_error_count + $system_zip_error_count)
        system_zip_total_warn_count=$(expr $system_zip_total_warn_count + system_zip_$warn_count)

      done < "$system_zip_file_list"
    else
      info_logging "- system.log.zip - There are 0 system.zip files"
      return
    fi

    #Calculate time difference for zip files
    system_zip_difference=$((current_date - system_zip_log_earliest_time))
    system_zip_diff_hours=$(($system_zip_difference / 3600))

    #Log information
    info_logging "- system.log.zip - There are $system_zip_total_error_count ERROR messages in system.zip files in the last $system_zip_diff_hours hour(s)"
    info_logging "- system.log.zip - There are $system_zip_total_warn_count WARN messages in system.zip files in the last $system_zip_diff_hours hour(s)"
}

#Function that reads debug.log.*.zip files to count errors and warnings
debug_zip_log_check()
{
    debug_zip_file_list=tmp/debug_zip_file_list.txt

    #Collect list of zip files
    ls $cassandra_log_path\debug*zip > $debug_zip_file_list 2>&-
    debug_zip_count=`cat $debug_zip_file_list | wc -l`

    debug_zip_total_error_count=0
    debug_zip_total_warn_count=0
    debug_zip_log_earliest_time=$(date +%s)

    #Check if zip files exist or not. If yes, parse them.
    if [ $debug_zip_count -gt 0 ]; then
      while IFS= read -r line
      do
        #Get start time of each file
        debug_zip_log_start_time=`zcat $line | head -1 | awk -F' ' '{print $3,$4}' | awk -F',' '{print $1}'`
        debug_zip_log_start_time_seconds=`date -d "$debug_zip_log_start_time" +%s`
        
        #Calculate earliest time
        if [ $debug_zip_log_start_time_seconds -lt $debug_zip_log_earliest_time ]; then
          debug_zip_log_earliest_time=$debug_zip_log_start_time_seconds
        else
          :
        fi

        #Get ERROR and WARN count of each file
        debug_zip_error_count=`zgrep ^ERROR $line | wc -l`
        debug_zip_warn_count=`zgrep ^WARN $line | wc -l`

        debug_zip_total_error_count=$(expr $debug_zip_total_error_count + $debug_zip_error_count)
        debug_zip_total_warn_count=$(expr $debug_zip_total_warn_count + $debug_zip_warn_count)

      done < "$debug_zip_file_list"
    else
      info_logging "- debug.log.zip - There are 0 debug.zip files"
      return
    fi

    #Calculate time difference for zip files
    debug_zip_difference=$((current_date - debug_zip_log_earliest_time))
    debug_zip_diff_hours=$(($debug_zip_difference / 3600))

    #Log information
    info_logging "- debug.log.zip - There are $debug_zip_total_error_count ERROR messages in debug.zip files in the last $debug_zip_diff_hours hour(s)"
    info_logging "- debug.log.zip - There are $debug_zip_total_warn_count WARN messages in debug.zip files in the last $debug_zip_diff_hours hour(s)"
}



system_log_check
debug_log_check
system_zip_log_check
debug_zip_log_check
