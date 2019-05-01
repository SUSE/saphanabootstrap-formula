{%- from "hana/map.jinja" import hana with context -%}
{% set host = grains['host'] %}

{% for node in hana.nodes %}
{% if node.host == host and node.scenario_type is defined and node.scenario_type.lower() == 'cost-optimized' %}

reduce_memory_resources_{{  node.host+node.sid }}:
    hana.memory_resources_updated:
      - name: {{  node.host }}
      {% if node.cost_optimized_parameters is defined %}
      - global_allocation_limit: {{ node.cost_optimized_parameters.global_allocation_limit }}
      - preload_column_tables: {{ node.cost_optimized_parameters.preload_column_tables }}
      {% endif %}
      - sid: {{  node.sid }}
      - inst: {{  node.instance }}
      - password: {{  node.password }}
      - require:
        - hana_install_{{ node.host+node.sid }}
{% endif %}

{% if node.host == host and node.secondary is defined %}

setup_srHook_directory:
    file.directory:
      - name: /hana/shared/srHook
      - user: root
      - mode: 755
      - makedirs: True

install_srTakeover_hook:
    file.managed:
      - source: salt://hana/templates/srTakeover_hook.j2
      - name: /hana/shared/srHook/sr-Takeover.py
      - user: root
      - group: root
      - mode: 644
      - template: jinja
      - require:
        - reduce_memory_resources_{{ node.host+node.sid }}
        - setup_srHook_directory

install_hana_python_packages:
    archive.extracted:
      - name: /hana/shared/srHook
      - enforce_toplevel: False
      - source: {{ grains['hana_inst_folder']~'/DATA_UNITS/HDB_CLIENT_LINUX_X86_64/client/PYDBAPI.TGZ' }}
      - require:
        - reduce_memory_resources_{{ node.host+node.sid }}
        - setup_srHook_directory

{% endif %}
{% endfor %}