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
      - name: /hana/shared/srHook/sr-Takeover.py
      - user: {{ node.sid.lower() }}adm
      - group: sapsys
      - template: jinja
      - require:
        - reduce_memory_resources_{{ node.host+node.sid }}
        - setup_srHook_directory

{% set platform = grains['cpuarch'].upper() %}
{% if platform not in ['X86_64', 'PPC64LE'] %}
failure:
  test.fail_with_changes:
    - name: 'not supported platform. only x86_64 and ppc64le are supported'
    - failhard: True
{% endif %}

{% set py_packages_folder = '{}/DATA_UNITS/HDB_CLIENT_LINUX_{}/client/PYDBAPI.TGZ'.format(grains['hana_inst_folder'], platform) %}

install_hana_python_packages:
    archive.extracted:
      - name: /hana/shared/srHook
      - user: {{ node.sid.lower() }}adm
      - group: sapsys
      - enforce_toplevel: False
      - source: {{ py_packages_folder }}
      - require:
        - reduce_memory_resources_{{ node.host+node.sid }}
        - setup_srHook_directory
{% endif %}
{% endif %}
{% endfor %}
