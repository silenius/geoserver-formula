{% from "geoserver/map.jinja" import geoserver with context %}

geoserver_home:
  file.directory:
    - name: {{ geoserver.root }}
    - user: root
    - group: wheel
    - mode: 755

{% for instance, config in geoserver.instances.items() %}

{{ instance }}_jdk_pkg:
  pkg.installed:
    - name: {{ config.jdk_conf.pkg }}

{{ instance }}_geoserver_archive:
  archive.extracted:
    - name: {{ config.root }}
    - user: {{ config.user }}
    - group: {{ config.group }}
    - source: {{ config.source }}
    - source_hash: {{ config.source_hash }}
    - enforce_toplevel: False
    - require:
      - file: geoserver_home
      - pkg: {{ instance }}_jdk_pkg


{% if config.plugins is defined %}
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
{% endif %}

{{ instance }}_geoserver_fix_bin:
  file.directory:
    - name: {{ config.bin_dir }}
    - user: {{ config.user }}
    - group: {{ config.group }}
    - file_mode: 755
    - recurse:
      - user
      - group
      - mode
    - require:
      - archive: {{ instance }}_geoserver_archive

{% endfor %}
