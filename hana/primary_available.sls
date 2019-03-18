{%- from "hana/map.jinja" import hana with context -%}
{% set host = grains['host'] %}

{% for node in hana.nodes %}
{% if node.host == host and node.secondary is defined %}
netcat-openbsd:
  pkg.installed

primary-available:
  cmd.run:
    - name: until nc -z {{  node.secondary.remote_host }} 40002; do sleep 1; done
    - timeout: {{  node.secondary.primary_timeout|default(100) }}
    - require:
      - netcat-openbsd

{% endif %}
{% endfor %}
