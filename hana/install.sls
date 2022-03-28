{%- from "hana/map.jinja" import hana with context -%}
{%- from 'hana/macros/get_hana_exe_extract_dir.sls' import get_hana_exe_extract_dir with context %}
{% set host = grains['host'] %}
{% set hana_extract_dir = get_hana_exe_extract_dir(hana) %}

include:
    - .enable_cost_optimized

{% for node in hana.nodes if node.host == host %}
{% if node.install is defined %}

{% set instance = '{:0>2}'.format(node.instance) %}
{% set sap_instance = '{}_{}'.format(node.sid, instance) %}
{% if node.install.extra_parameters is defined and node.install.extra_parameters|length > 0 %}
  {%set extra_parameters = True %}
  {%set extra_parameters_items = node.install.extra_parameters.items() %}
{% else %}
  {%set extra_parameters = False %}
  {%set extra_parameters_items = [] %}
{% endif %}

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
    {% if extra_parameters %}
      {% for key,value in extra_parameters_items %}
      {% if key != 'addhosts' %} # exclude addhosts (scale-out)
      - {{ key }}: {{ value }}
      {% endif %}
      {% endfor %}
    {% endif %}
    - remove_pwd_files: False

# scale-out specific
{% for key,value in extra_parameters_items %}
{% if key == 'addhosts' %}

# SAP Note 2080991
{% if not hana.basepath_shared|default(True) %}
disable_basepath_shared_{{ sap_instance }}:
  module.run:
    - hana.set_ini_parameter:
      - ini_parameter_values:
        - section_name: 'persistence'
          parameter_name: 'basepath_shared'
          parameter_value: 'no'
      - database: SYSTEMDB
      - file_name: global.ini
      - layer: SYSTEM
      - reconfig: True
      - user_name: SYSTEM
      - user_password: {{ node.password }}
      - password: {{ node.password }}
      - sid: {{ node.sid }}
      - inst: {{ node.instance }}
{% endif %}

# add scale-out nodes
hana_add_hosts_{{ node.host+node.sid }}:
  module.run:
    - hana.add_hosts:
      - add_hosts: {{ value }}
      - hdblcm_folder: /hana/shared/{{ node.sid.upper() }}/hdblcm
      - root_user: {{ node.install.root_user }}
      - root_password: {{ node.install.root_password }}
      - hdb_pwd_file: /root/hdb_passwords.xml
    # only run after initial install (password file still exists)
    - onlyif:
      - test -f /root/hdb_passwords.xml

hana_add_hosts_pwd_file_remove_{{ node.host+node.sid }}:
  file.absent:
    - name: /root/hdb_passwords.xml

{% endif %}
{% endfor %}

{% else %} # node.install not defined
# make sure /hana/{data,log}/${SID} exists on nodes where install does not run

create_hana_data_{{ node.sid.upper() }}:
  file.directory:
    - name: /hana/data/{{ node.sid.upper() }}
    # - user: {{ node.sid.lower() }}adm # user might not exist yet
    # - group: sapsys                   # group might not exist yet
    - mode: 750
    - makedirs: True

create_hana_log_{{ node.sid.upper() }}:
  file.directory:
    - name: /hana/log/{{ node.sid.upper() }}
    # - user: {{ node.sid.lower() }}adm # user might not exist yet
    # - group: sapsys                   # group might not exist yet
    - mode: 750
    - makedirs: True

{% endif %}
{% endfor %}
