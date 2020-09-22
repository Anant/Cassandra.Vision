# currently assumes localhost
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

curl -X POST "localhost:5601/api/saved_objects/_import" \
  -H "kbn-xsrf: true" \
  --form file=@$parent_path/../exported-objects/export-v1.1.ndjson \
  -H 'kbn-xsrf: true'

