{% from "geoserver/map.jinja" import geoserver with context %}

include:
  - geoserver.install

{% for instance, config in geoserver.instances.items() %}
{% for plugin in config.plugins %}
{{ instance }}_geoserver_plugin_{{ plugin.plugin }}:
  archive.extracted:
    - name: {{ config.lib }}
    - user: {{ config.user }}
    - group: {{ config.group }}
    - enforce_toplevel: False
    - source: {{ plugin.source }}
    - source_hash: {{ plugin.source_hash }}
    - require:
      - archive: {{ instance }}_geoserver_archive
    - require_in:
      - file: {{ instance }}_geoserver_fix_bin
{% endfor %}
{% endfor %}
