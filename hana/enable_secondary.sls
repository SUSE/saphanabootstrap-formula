{%- from "hana/map.jinja" import hana with context -%}
{% set host = grains['host'] %}

{% for node in hana.nodes %}
{% if node.host == host and node.secondary is defined %}

{% for prim_node in hana.nodes %}
{% if node.secondary.remote_host == prim_node.host and prim_node.primary is defined %}
{% set primary_pass = prim_node.password %}

{{  node.secondary.name }}:
  hana.sr_secondary_registered:
    - sid: {{  node.sid }}
    - inst: {{  node.instance }}
    - password: {{  node.password }}
    - remote_host: {{  node.secondary.remote_host }}
    - remote_instance: {{  node.secondary.remote_instance }}
    - replication_mode: {{  node.secondary.replication_mode }}
    - operation_mode: {{  node.secondary.operation_mode }}
    - timeout: {{ node.secondary.primary_timeout|default(100) }}
    - interval: {{ node.secondary.interval|default(10) }}
    - primary_pass: {{ primary_pass }}

{% endif %}
{% endfor %}
{% endif %}
{% endfor %}
