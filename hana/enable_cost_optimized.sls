{%- from "hana/map.jinja" import hana with context -%}
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

install_srTakeover_hook:
    file.managed:
      - source: salt://hana/templates/srTakeover_hook.j2
      - name: /hana/shared/srHook/srTakeover.py
      - user: {{ node.sid.lower() }}adm
      - group: sapsys
      - template: jinja
      - require:
        - reduce_memory_resources_{{ node.host+node.sid }}
        - setup_srHook_directory

install_hana_python_packages:
    archive.extracted:
      - name: /hana/shared/srHook
      - user: {{ node.sid.lower() }}adm
      - group: sapsys
      - enforce_toplevel: False
      - source: {{ grains['hana_inst_folder']~'/DATA_UNITS/HDB_CLIENT_LINUX_X86_64/client/PYDBAPI.TGZ' }}
      - options: --strip=1 --wildcards 'hdbcli/*.py'
      - require:
        - reduce_memory_resources_{{ node.host+node.sid }}
        - setup_srHook_directory

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
        - install_hana_python_packages
{% endif %}
{% endif %}
{% endfor %}