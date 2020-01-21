{%- from "hana/map.jinja" import hana with context -%}
{% set host = grains['host'] %}

{% for node in hana.nodes if node.host == host and (hana.saptune_solution is defined or node.saptune_solution is defined) %}

{% set saptune_solution = node.saptune_solution|default(hana.saptune_solution) %}
{% set instance = '{:0>2}'.format(node.instance) %}
{% set name = '{}_{}'.format(node.sid, instance) %}

apply_saptune_solution_{{ host }}_{{ name }}:
  saptune.solution_applied:
    - name: {{ saptune_solution }}

{% endfor %}
