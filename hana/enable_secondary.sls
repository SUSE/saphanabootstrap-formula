{%- from "hana/map.jinja" import hana with context -%}
{% set host = grains['host'] %}

include:
  - .copy_ssfs

{% for node in hana.nodes %}
{% if node.host == host and node.secondary is defined %}

primary_available:
  cmd.run:
    - name: until nc -z {{  node.secondary.remote_host }} 40002; do sleep 1; done
    - timeout: 100

{{  node.secondary.name }}:
    hana.sr_secondary_registered:
      - sid: {{  node.sid }}
      - inst: {{  node.instance }}
      - password: {{  node.password }}
      - remote_host: {{  node.secondary.remote_host }}
      - remote_instance: {{  node.secondary.remote_instance }}
      - replication_mode: {{  node.secondary.replication_mode }}
      - operation_mode: {{  node.secondary.operation_mode }}
      - require:
        - primary_available
        - hana_install_{{ node.host+node.sid }}

{% endif %}
{% endfor %}
