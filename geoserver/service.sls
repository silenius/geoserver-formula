{% from "geoserver/map.jinja" import geoserver with context %}

include:
  - runit

{% for instance, config in geoserver.instances.items() %}
{{ instance }}_geoserver_service:
  file.managed:
    - name: /var/service/geoserver_{{ instance }}/run
    - user: root
    - group: wheel
    - mode: 755
    - makedirs: True
    - contents: |
        #!/bin/sh
        exec chpst -u {{ config.user }} \
        /bin/sh -c '
        export JAVA_HOME="{{ config.jdk_conf.JAVA_HOME }}"
        export GEOSERVER_DATA_DIR="{{ config.GEOSERVER_DATA_DIR }}"
        export GEOSERVER_LOG_LOCATION="{{ config.log }}"
        export GEOSERVER_REQUIRE_FILE="{{ config.GEOSERVER_DATA_DIR | path_join('global.xml') }}"
        export GWC_DISKQUOTA_DISABLED=true
        export GWC_METASTORE_DISABLED=true
        export GEOSERVER_CSRF_WHITELIST="{{ config.GEOSERVER_CSRF_WHITELIST }}"
        export JAVA_OPTS="{{ config.jdk_conf.JAVA_OPTS }}"
        cd {{ config.bin_dir }}
        ./startup.sh
        '
{% endfor %}
