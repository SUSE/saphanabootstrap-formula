{%- from "hana/map.jinja" import hana with context -%}
{% set host = grains['host'] %}

{% for node in hana.nodes %}
{% if node.host == host and node.exporter is defined %}

{% set instance = '{:0>2}'.format(node.instance) %}
{% set config_file = '/etc/hanadb_exporter/config_{}_{}.json'.format(node.sid, instance) %}

hanadb_exporter:
  pkg.installed

python3-PyHDB:
  pkg.installed

configure_exporter:
  file.managed:
    - source: salt://hana/templates/hanadb_exporter.j2
    - name: {{ config_file }}
    - template: jinja
    - require:
      - hanadb_exporter
      - python3-PyHDB

stop_exporter:
  process.absent:
    - name: hanadb_exporter -c {{ config_file }} -m /etc/hanadb_exporter/metrics.json
    - require:
        - configure_exporter

start_exporter:
  cmd.run:
    - name: nohup hanadb_exporter -c {{ config_file }} -m /etc/hanadb_exporter/metrics.json &>/dev/null &
    - require:
        - configure_exporter

{% endif %}
{% endfor %}
