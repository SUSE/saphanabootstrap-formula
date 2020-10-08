{%- from "hana/map.jinja" import hana with context -%}
{%- from 'hana/macros/get_hana_exe_extract_dir.sls' import get_hana_exe_extract_dir with context %}
{% set hana_extract_dir = get_hana_exe_extract_dir(hana) %}

{% set host = grains['host'] %}

{% for node in hana.nodes %}
{% if node.host == host and node.scenario_type is defined and node.scenario_type.lower() == 'cost-optimized' and node.cost_optimized_parameters is defined%}

reduce_memory_resources_{{  node.host+node.sid }}:
    hana.memory_resources_updated:
      - name: {{  node.host }}
      - global_allocation_limit: {{ node.cost_optimized_parameters.global_allocation_limit }}
      - preload_column_tables: {{ node.cost_optimized_parameters.preload_column_tables }}
      - user_name: SYSTEM
      {% if node.install.system_user_password is defined %}
      - user_password: {{ node.install.system_user_password }}
      {% endif %}
      - sid: {{  node.sid }}
      - inst: {{  node.instance }}
      - password: {{  node.password }}
      - require:
        - hana_install_{{ node.host+node.sid }}

{% if node.host == host and node.secondary is defined %}

setup_srHook_directory:
    file.directory:
      - name: /hana/shared/srHook
      - user: {{ node.sid.lower() }}adm
      - group: sapsys
      - mode: 755
      - makedirs: True
      - require:
        - reduce_memory_resources_{{ node.host+node.sid }}

install_srTakeover_hook:
    file.managed:
      - source: salt://hana/templates/srTakeover_hook.j2
      - name: /hana/shared/srHook/srTakeover.py
      - user: {{ node.sid.lower() }}adm
      - group: sapsys
      - mode: 755
      - template: jinja
      - require:
        - setup_srHook_directory

{% set platform = grains['cpuarch'].upper() %}
{% if platform not in ['X86_64', 'PPC64LE'] %}
failure:
  test.fail_with_changes:
    - name: 'not supported platform. only x86_64 and ppc64le are supported'
    - failhard: True
{% endif %}

extract_hana_pydbapi_archive:
    hana.pydbapi_extracted:
      - name: PYDBAPI.TGZ
      - software_folders: [{{ node.install.software_path|default(hana.software_path)|default(hana_extract_dir) }}]
      - output_dir: /hana/shared/srHook
      - hana_version: '20'
      - force: true
      - additional_extract_options: --transform s|-[0-9]*\.[0-9]*\.[0-9]*|-package| --wildcards hdbcli*
      - require:
        - setup_srHook_directory

extract_hdbcli_client_files:
    archive.extracted:
      - name: /hana/shared/srHook/
      - source: /hana/shared/srHook/hdbcli-package.tar.gz
      - enforce_toplevel: False
      - options:  --strip=2 --wildcards '*/hdbcli/*.py'
      - require:
        - extract_hana_pydbapi_archive

remove_hdbcli_tar_package:
    file.absent:
      - names: 
        - /hana/shared/srHook/hdbcli-package.tar.gz
        - /hana/shared/srHook/hdbcli
      - require:
        - extract_hdbcli_client_files
        
chmod_hdbcli_client_files:
    file.managed:
      - user: {{ node.sid.lower() }}adm
      - group: sapsys
      - mode: 755
      - names:
        - /hana/shared/srHook/dbapi.py
        - /hana/shared/srHook/resultrow.py
        - /hana/shared/srHook/__init__.py
      - require:
        - extract_hdbcli_client_files

configure_ha_dr_provider_srTakeover:
    file.append:
      - name:  /hana/shared/{{ node.sid.upper() }}/global/hdb/custom/config/global.ini
      - text: |

          [ha_dr_provider_srTakeover]
          provider = srTakeover
          path = /hana/shared/srHook
          execution_order = 1
      - require:
        - reduce_memory_resources_{{ node.host+node.sid }}
        - setup_srHook_directory
        - install_srTakeover_hook
        - extract_hdbcli_client_files
{% endif %}
{% endif %}
{% endfor %}
