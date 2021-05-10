# Installing Filebeat, Elasticsearch & Kibana for Log analysis
Currently ansible is only setup to run using the apt package manager, but we plan on adding Redhat compatibility soon. 

### Install all
Say hello to server to make sure ssh works. If you are running on localhost make an entry like this in your hosts.ini so you can bypass SSH.

```
localhost ansible_connection=local	
```

```
ansible-playbook -i ./envs/elk/hosts.ini ./playbooks/hello.yml
```
The next command installs:
- install elasticsearch
- install kibana
- install logstash
- install filebeats

```
ansible-playbook -i ./envs/elk/hosts.ini ./playbooks/elk-install.yml
```

## TODOs:
- run elasticsearch with docker
- playbook for redhat
- Redhat on ansible

#### Reference for Redhat Installation

- https://www.elastic.co/guide/en/elasticsearch/reference/current/rpm.html
- https://www.elastic.co/guide/en/kibana/current/rpm.html
- https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-installation.html

