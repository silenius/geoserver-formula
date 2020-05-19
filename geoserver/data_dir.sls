{% from "geoserver/map.jinja" import geoserver with context %}

include:
  - geoserver.install

{% for instance, config in geoserver.instances.items() %}

{{ instance }}_geoserver_data_dir:
  file.directory:
    - name: {{ config.GEOSERVER_DATA_DIR }}
    - makedirs: True
    - user: {{ config.user }}
    - group: {{ config.group }}
    - require:
      - archive: {{ instance }}_geoserver_archive
  cmd.run:
    - name: cp -R {{ config.data_dir.rstrip('/') ~ '/' }} {{ config.GEOSERVER_DATA_DIR }}
    - require:
      - file: {{ instance }}_geoserver_data_dir
    - unless:
      - ls -A {{ config.GEOSERVER_DATA_DIR }} | grep -q .

{{ instance }}_geoserver_data_dir_permissions:
  file.directory:
    - name: {{ config.GEOSERVER_DATA_DIR }}
    - user: {{ config.user }}
    - group: {{ config.group }}
    - recurse:
      - user
      - group
      - mode
    - dir_mode: 750
    - file_mode: 640
    - onchanges:
      - cmd: {{ instance }}_geoserver_data_dir

{% endfor %}
