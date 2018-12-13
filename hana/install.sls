{%- from "hana/map.jinja" import hana with context -%}
{% set host = grains['host'] %}

{% for node in hana.nodes %}
{% if node.host == host and node.install is defined and node.install_checkbox == true %}

hana_install_{{ node.host+node.sid }}:
  hana.installed:
    - sid: {{ node.sid }}
    - inst: {{ node.instance }}
    - password: {{ node.password }}
    - software_path: {{ node.install.software_path }}
    - root_user: {{ node.install.root_user }}
    - root_password: {{ node.install.root_password }}
    {% if node.install.config_file is defined and node.install.use_config_file == true %}
    - config_file: {{ node.install.config_file }}
    {% else %}
    - system_user_password: {{ node.install.system_user_password }}
    {% endif %}
    {% if node.install.extra_parameters is defined and node.install.extra_parameters|length > 0 %}
    - extra_parameters:
      {% for key,value in node.install.extra_parameters.items() %}
      - {{ key }}: {{ value }}
      {% endfor %}
    {% endif %}

{% endif %}
{% endfor %}
