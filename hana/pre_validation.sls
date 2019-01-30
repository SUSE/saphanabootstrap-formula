{%- from "hana/map.jinja" import hana with context -%}

{% set host = grains['host'] %}

{% for node in hana.nodes %}
{% if node.host == host %}

{# Check HANA insatll checkbox #}
{% if node.install_checkbox is defined and node.install_checkbox == false %}

{% do node.pop('install') %}

{% elif node.install.use_config_file == false %}

{% do node.install.pop('config_file') %}

{% endif %}
{# Check HANA insatll checkbox finish #}

{# Check HANA Systen replication mode #}
{% if node.system_replication.system_replication_options is defined and node.system_replication.system_replication_options != "Secondary" %}

{% do node.pop('secondary') %}

{% endif %}

{% if node.system_replication.system_replication_options is defined and node.system_replication.system_replication_options != "Primary" %}

{% do node.pop('primary') %}

{% else %}

{% if node.primary.create_backup == false %}

{% do node.primary.pop('backup') %}

{% endif %}

{% if node.primary.create_userkey == false %}

{% do node.primary.pop('userkey') %}

{% endif %}

{% endif %}
{# Check HANA Systen replication mode finish #}

{% endif %}
{% endfor %}
