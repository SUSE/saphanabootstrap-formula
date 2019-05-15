{%- from "hana/map.jinja" import hana with context -%}
{% set host = grains['host'] %}

include:
    - .enable_cost_optimized

{% for node in hana.nodes %}
{% if node.host == host and node.install is defined %}

hana_install_{{ node.host+node.sid }}:
  hana.installed:
    - name: {{ node.sid }}
    - inst: {{ node.instance }}
    - password: {{ node.password }}
    - software_path: {{ node.install.software_path }}
    - root_user: {{ node.install.root_user }}
    - root_password: {{ node.install.root_password }}
    {% if node.install.config_file is defined %}
    - config_file: {{ node.install.config_file }}
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

{% endif %}
{% endfor %}
