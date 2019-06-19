{%- from "hana/map.jinja" import hana with context -%}
{% set host = grains['host'] %}

{% for node in hana.nodes %}
{% if node.host == host and node.exporter is defined %}

{% set config_file = '/etc/hanadb_exporter/config_{{ node.sid.lower() }}_{{ '{:0>2}'.format(node.instance) }}.json' %}

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
        - python-PyHDB

start_exporter:
  cmd.run:
    - name: hanadb_exporter -c {{ config_file }} -m /etc/hanadb_exporter/metrics.json
    - unless: ps -ef | grep 'hanadb_exporter -c {{ config_file }} -m /etc/hanadb_exporter/metrics.json'
    - require:
        - configure_exporter

{% endif %}
{% endfor %}
