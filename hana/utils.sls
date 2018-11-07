# Shared resources

{%- from "hana/map.jinja" import hana with context -%}

{% set path = '/usr/sap/'+ hana.sid.upper() +'/HDB'+hana.instance %}
{% set user = hana.sid+'adm' %}
