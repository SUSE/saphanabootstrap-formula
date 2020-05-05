{%- from "hana/map.jinja" import hana with context -%}

include:
  - hana.install_pydbapi

prometheus-hanadb_exporter:
  pkg.installed:
  - retry:
      attempts: 3
      interval: 15

hanadb_exporter_logging_configuration:
  file.managed:
    - name: /etc/hanadb_exporter/logging_config.ini
    - source: /usr/etc/hanadb_exporter/logging_config.ini
    - require:
      - prometheus-hanadb_exporter

hanadb_exporter_metrics_configuration:
  file.managed:
    - name: /etc/hanadb_exporter/metrics.json
    - source: /usr/etc/hanadb_exporter/metrics.json
    - require:
      - prometheus-hanadb_exporter

{% for node in hana.nodes if node.host == grains['host'] %}

{% set sap_instance_nr = '{:0>2}'.format(node.instance) %}
{% set exporter_instance = '{}_HDB{}'.format(node.sid.upper(), sap_instance_nr) %}

hanadb_exporter_configuration_{{ exporter_instance }}:
  file.managed:
    - source: salt://hana/templates/hanadb_exporter.j2
    - name: /etc/hanadb_exporter/{{ exporter_instance }}.json
    - template: jinja
    - require:
      - prometheus-hanadb_exporter
      - hanadb_exporter_metrics_configuration_{{ exporter_instance }}
      - hanadb_exporter_logging_configuration_{{ exporter_instance }}
    - context:
        node: {{ node|yaml }}
        sap_instance_nr: {{ sap_instance_nr }}
        exporter_instance: {{ exporter_instance }}

hanadb_exporter_service_{{ exporter_instance }}:
  service.running:
    - name: prometheus-hanadb_exporter@{{ exporter_instance }}
    - enable: {{ not hana.ha_enabled }}
    - reload: True
    - require:
        - hanadb_exporter_configuration_{{ exporter_instance }}
        - hana_install_pydbapi_client

{% endfor %}
