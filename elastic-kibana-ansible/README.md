# Installing Filebeat, Elasticsearch & Kibana for Log analysis
If you don't have Filebeat, Elasticsearch & Kibana installed on your machine already, you can use our Ansible playbook to do it for you.

Table of Contents
- [Setup your hosts.ini file](#Setup-your-hostsini-file)
    - [Running on localhost?](#Running-on-localhost)
    - [Test connection](#Test-connection)
- [Install ELK](#Install-ELK)
- [Debugging](#Debugging)
- [Compatibility](#Compatibility)
- [Development](#development)
- [TODOs](#TODOs)

# Setup your hosts.ini file
You will need to setup the hosts.ini file at `./envs/elk/hosts.ini`.

### Running on localhost?
If you are running on localhost, delete what is currently there in `./envs/elk/hosts.ini` and replace it with this so you can bypass SSH.
```
[elk]
localhost ansible_connection=local	
```

You might also need to use the `--ask-become-pass` flag whenever executing the playbook. E.g., 

```
ansible-playbook -i ./envs/elk/hosts.ini ./playbooks/elk-install.yml --ask-become-pass
```

### Test SSH connection
To make sure your hosts.ini file is configured correctly, run the `hello.yml` playbook.
```
ansible-playbook -i ./envs/elk/hosts.ini ./playbooks/hello.yml
```

# Install ELK
The next command installs:
- install elasticsearch
- install kibana
- *install logstash (TODO not yet configured)*
- *install filebeat (TODO not yet configured)*

```
ansible-playbook -i ./envs/elk/hosts.ini ./playbooks/elk-install.yml
```

Elasticsearch should now be running at port 9200, and connected to kibana running at port 5601. 

### What about Filebeat and Logstash?
Currently, we are not installing logstash and filebeat, since logstash is not needed for cassandra.vision and filebeat is often installed on a separate host than elasticsearch and kibana, so for now we are keeping it separate. 

You can find instructions for installing filebeat at [the official filebeat documentation](https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-installation-configuration.html).

### What's Next
Now you are ready to start ingesting your Cassandra logs into Elasticsearch using filebeat. 

- [Click here to generate your log tarball](../cassandra-analyzer/offline-log-collector/README.md).
- [Click here if you already have a log tarball, and you are ready to start ingesting](../cassandra-analyzer/offline-log-ingester/README.md).

# Compatibility
Currently ansible is only setup to run using the apt package manager, but we plan on adding Redhat compatibility soon. 

# Debugging
Below are some of the areas you might run into and possible solutions. 

### ERROR: `sudo: a password is required`
The full error might look something like this, e.g., 
```
=> ansible-playbook -i ./envs/elk/hosts.ini ./playbooks/elk-install.yml

PLAY [elk] *************************************************************************************************************************************************

TASK [Gathering Facts] *************************************************************************************************************************************
fatal: [localhost]: FAILED! => {"ansible_facts": {}, "changed": false, "failed_modules": {"setup": {"ansible_facts": {"discovered_interpreter_python": "/usr/bin/python"}, "deprecations": [{"msg": "Distribution Ubuntu 18.04 on host localhost should use /usr/bin/python3, but is using /usr/bin/python for backward compatibility with prior Ansible releases. A future Ansible release will default to using the discovered platform python for this host. See https://docs.ansible.com/ansible/2.9/reference_appendices/interpreter_discovery.html for more information", "version": "2.12"}], "failed": true, "module_stderr": "sudo: a password is required\n", "module_stdout": "", "msg": "MODULE FAILURE\nSee stdout/stderr for the exact error", "rc": 1}}, "msg": "The following modules failed to execute: setup\n"}
```

Solution: 
Be sure to use the `--ask-become-pass` flag when executing the ansible playbook.

### ERROR: `Unable to restart service elasticsearch`
E.g., 

```
TASK [start and enable es service] *************************************************************************************************************************fatal: [localhost]: FAILED! => {"changed": false, "msg": "Unable to restart service elasticsearch: Job for elasticsearch.service failed because the control process exited with error code.\nSee \"systemctl status elasticsearch.service\" and \"journalctl -xe\" for details.\n"}
```

Solution:
Check out the elasticsearch logs, and debug accordingly.
```
tail -f /var/log/elasticsearch/elasticsearch.log
```


# Development
TODO add instructions for developing and contributing to elastic-kibana-ansible.

# TODOs:
- run elasticsearch with docker
- playbook for redhat
- Redhat on ansible

#### Reference for Redhat Installation

- https://www.elastic.co/guide/en/elasticsearch/reference/current/rpm.html
- https://www.elastic.co/guide/en/kibana/current/rpm.html
- https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-installation.html
