{%- from "hana/map.jinja" import hana with context -%}
{%- from 'hana/macros/get_hana_client_path.sls' import get_hana_client_path with context %}

{% for node in hana.nodes if node.host == grains['host'] %}

{%- set pydbapi_output_dir = '/tmp/pydbapi' %}
{%- set hana_client_path = get_hana_client_path(hana, node ) %}

# only run if exporter is defined
{% if node.exporter is defined and node.instance is defined and node.sid is defined %}
{% set exporter = node.exporter|default(None) %}

{% set sap_instance_nr = '{:0>2}'.format(node.instance) %}
{% set exporter_instance = '{}_HDB{}'.format(node.sid.upper(), sap_instance_nr) %}

install_python_pip:
  pkg.installed:
    - name: python3-pip
    - retry:
        attempts: 3
        interval: 15
    - resolve_capabilities: true

extract_pydbapi_client:
  hana.pydbapi_extracted:
    - name: PYDBAPI.TGZ
    - software_folders: [{{ hana_client_path }}]
    - output_dir: {{ pydbapi_output_dir }}
    - hana_version: '20'
    - force: true

# pip.installed cannot manage file names with regular expressions
# TODO: Improve this to use pip.installed somehow
install_pydbapi_client:
  cmd.run:
    - name: /usr/bin/python3 -m pip install {{ pydbapi_output_dir }}/hdbcli-*.tar.gz
    - require:
      - install_python_pip
      - extract_pydbapi_client

prometheus-hanadb_exporter:
  pkg.installed:
  - retry:
      attempts: 3
      interval: 15
  - require:
      - install_pydbapi_client

hanadb_exporter_configuration_{{ exporter_instance }}:
  file.managed:
    - source: salt://hana/templates/hanadb_exporter.j2
    - name: /usr/etc/hanadb_exporter/{{ exporter_instance }}.json
    - template: jinja
    - mode: '0700'
    - require:
      - prometheus-hanadb_exporter
    - context:
        exporter: {{ exporter|yaml }}
        sap_instance_nr: "{{ sap_instance_nr }}"
        exporter_instance: {{ exporter_instance }}

{% if hana.ha_enabled %}
{% set service_status = "disabled" %}
{% set service_enabled = False %}
{% else %}
{% set service_status = "running" %}
{% set service_enabled = True %}
{% endif %}

hanadb_exporter_service_{{ exporter_instance }}:
  service.{{ service_status }}:
    - name: prometheus-hanadb_exporter@{{ exporter_instance }}
    - enable: {{ service_enabled }}
    {% if service_enabled %}
    - watch:
      - file: hanadb_exporter_configuration_{{ exporter_instance }}
    {% endif %}

{% endif %}
{% endfor %}
