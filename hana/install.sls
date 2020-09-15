{%- from "hana/map.jinja" import hana with context -%}
{% set host = grains['host'] %}

include:
    - .enable_cost_optimized

{% for node in hana.nodes if node.host == host and node.install is defined %}

# TODO this create maybe to much dependencies with grains from ha-deployement
# maybe create a general grain called ad_enabled = TRUE/FALSE

{% if grains.get('ad_server', True) %}
# this state is used in case we have ad integration and grains are passed to installation
add_sidadm_grains:
  cmd.run:
    - name: |
        sed -i '/sid_uid/d' /etc/salt/grains
        sed -i '/sid_gid/d' /etc/salt/grains
        echo "sid_uid: `id {{node.sid}}adm -u`" >> /etc/salt/grains
        echo "sid_gid: `id {{node.sid}}adm -g`" >> /etc/salt/grains
{% endif %}

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
    {% endif %}
    {% if node.install.hdb_pwd_file is defined %}
    - hdb_pwd_file: {{ node.install.hdb_pwd_file }}
    {% else %}
    - system_user_password: {{ node.install.system_user_password }}
    - sapadm_password: {{ node.install.sapadm_password }}
    {% endif %}
    - extra_parameters:
      - hostname: {{ node.host }}
      {% if grains.get('ad_server', True) %}
      - userid:  {{ grains['sid_uid'] }}
      - groupid: {{ grains['sid_gid'] }}
      {% endif %}
    {% if node.install.extra_parameters is defined and node.install.extra_parameters|length > 0 %}
      {% for key,value in node.install.extra_parameters.items() %}
      - {{ key }}: {{ value }}
      {% endfor %}
    {% endif %}
{% endfor %}
