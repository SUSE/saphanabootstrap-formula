{%- from "hana/map.jinja" import hana with context -%}
{% set host = grains['host'] %}
{% set hana_extract_dir = hana.hana_extract_dir %}

# Below is temporary workaround to update the software installation path when using unrar for HANA multipart rar archive#
# TODO: Find better solution to set or detect the correct extraction path when extracting multipart rar archive
# Below logic finds the extraction location based on name of multipart exe archive filename
{%- if hana.hana_archive_file is defined and hana.hana_archive_file.endswith((".exe", ".EXE")) %}
{% set archive_base_name = salt['file.basename']( hana.hana_archive_file.split('.')[0]) %}
{% set archive_name = archive_base_name.split('_')[0] %}
{% set hana_extract_dir = hana_extract_dir| path_join(archive_name) %}
{% endif %}

include:
    - .enable_cost_optimized

{% for node in hana.nodes if node.host == host and node.install is defined %}

hana_install_{{ node.host+node.sid }}:
  hana.installed:
    - name: {{ node.sid }}
    - inst: {{ node.instance }}
    - password: {{ node.password }}
    - software_path: {{ node.install.software_path|default(hana.software_path)|default(hana_extract_dir) }}
    - root_user: {{ node.install.root_user }}
    - root_password: {{ node.install.root_password }}
    {% if node.install.config_file is defined %}
    - config_file: {{ node.install.config_file }}
    {% endif %}
    {% if node.install.hdb_pwd_file is defined %}
    - hdb_pwd_file: {{ node.install.hdb_pwd_file }}
    {% else %}
    - system_user_password: {{ node.install.system_user_password }}
    - sapadm_password: {{ node.install.sapadm_password }}
    {% endif %}
    - extra_parameters:
      - hostname: {{ node.host }}
    {% if node.install.extra_parameters is defined and node.install.extra_parameters|length > 0 %}
      {% for key,value in node.install.extra_parameters.items() %}
      - {{ key }}: {{ value }}
      {% endfor %}
    {% endif %}

{% endfor %}
