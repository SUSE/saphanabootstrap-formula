{% from "hana/map.jinja" import hana with context -%}

{% set host = grains['host'] %}

{% for node in hana.nodes if node.host == host %}

  {# Check HANA install checkbox #}
  {% if node.install_checkbox is defined and node.install_checkbox == false %}

    {% do node.pop('install') %}

  {% elif node.install_checkbox is defined and node.install_checkbox == true %}
    {% if node.install.use_config_file == false %}
      {% do node.install.pop('config_file') %}
    {% endif %}

    {% if node.install.extra_parameters is defined and node.install.extra_parameters|length > 0 and node.install.extra_parameters is not mapping %}
      {% set new_extra_parameters = {} %}
      {% for new_item in node.install.extra_parameters %}
        {% do new_extra_parameters.update({new_item.key:  new_item.value}) %}
      {% endfor %}
      {% do node.install.update({'extra_parameters': new_extra_parameters}) %}
    {% endif %}
  {% endif %}
  {# Check HANA install checkbox finish #}

  {# Check HANA System replication mode #}
  {% if node.system_replication is defined %}
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
  {% endif %}
  {# Check HANA Systen replication mode finish #}
  {# Check HANA exporter #}
  {% if node.add_exporter is defined and node.add_exporter == false %}
    {% do node.pop('exporter') %}
  {% endif %}
  {# Check HANA exporter finish #}

{% endfor %}
