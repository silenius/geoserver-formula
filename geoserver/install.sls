{% from "geoserver/map.jinja" import geoserver with context %}

geoserver_openjdk_pkg:
  pkg.installed:
    - name: {{ geoserver.openjdk_pkg }}

geoserver_home:
  file.directory:
    - name: {{ geoserver.base_dir }}
    - user: root
    - group: wheel
    - mode: 755
    - require:
      - pkg: geoserver_openjdk_pkg

{% for instance, config in geoserver.instances.items() %}

geoserver_archive:
  archive.extracted:
    - name: {{ geoserver.base_dir }}
    - user: {{ geoserver.user }}
    - group: {{ geoserver.user }}
    - source: salt://geoserver/files/geoserver-{{ geoserver.version }}-bin.zip
    - source_hash: md5={{ geoserver.files['geoserver-' ~ geoserver.version ~ '-bin.zip'] }}
    - if_missing: {{ geoserver.base_dir ~ '/geoserver-' ~ geoserver.version }}
    - archive_format: zip
    - require:
      - file: geoserver_home

{% endfor %}

{% for plugin in geoserver.plugins %}
{% set plugin_file = 'geoserver-' ~ geoserver.version ~ '-' ~ plugin ~ '-plugin.zip' %}
geoserver_plugin_{{ plugin }}:
  archive.extracted:
    - name: {{ geoserver.base_dir ~ '/geoserver-' ~ geoserver.version ~ '/webapps/geoserver/WEB-INF/lib/' }}
    - user: {{ geoserver.user }}
    - group: {{ geoserver.user }}
    - enforce_toplevel: False
    - source: salt://geoserver/files/{{ plugin_file }}
    - source_hash: md5={{ geoserver.files[plugin_file] }}
    - archive_format: zip
{% if plugin == 'printing' %}
    # See http://docs.geoserver.org/stable/en/user/extensions/printing/index.html#verifying-installation
    - if_missing: {{ geoserver.data_dir ~ '/printing/config.yaml' }}
{% elif plugin == 'excel' %}
    - if_missing: {{ geoserver.base_dir ~ '/geoserver-' ~ geoserver.version ~ '/webapps/geoserver/WEB-INF/lib/gs-excel-' ~ geoserver.version ~ '.jar' }}
{% elif plugin == 'wps' %}
    - if_missing: {{ geoserver.base_dir ~ '/geoserver-' ~ geoserver.version ~ '/webapps/geoserver/WEB-INF/lib/gs-wps-core-' ~ geoserver.version ~ '.jar' }}
{% endif %}
    - require:
      - archive: geoserver_archive
{% endfor %}

geoserver_fix_bin:
  file.directory:
    - name: {{ geoserver.base_dir ~ '/geoserver-' ~ geoserver.version ~ '/bin' }}
    - user: {{ geoserver.user }}
    - group: {{ geoserver.user }}
    - file_mode: 755
    - recurse:
      - user
      - group
      - mode
    - require:
      - archive: geoserver_archive

