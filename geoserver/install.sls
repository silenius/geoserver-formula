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

#############
# GEOSERVER #
#############

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

{{ instance }}_geoserver_web_xml:
  file.line:
    - name: {{ config.web_xml }}
    - content: |
        <!-- START managed_resource_ref -->

        <!-- END managed_resource_ref -->
    - mode: ensure
    - before: ^</web-app>

###############
# PERMISSIONS #
###############

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
