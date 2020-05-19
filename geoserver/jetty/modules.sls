{% from "geoserver/map.jinja" import geoserver with context %}

include:
  - geoserver.install

{% for instance, config in geoserver.instances.items() %}
{% for module, module_config in config.jetty.modules.items() %}

#######
# JAR #
#######

{% if module_config.name is defined %}

{% if module_config.enabled %}

{{ instance }}_jetty_module_{{ module }}:
  file.managed:
    - name: {{ module_config.name }} 
    - source: {{ module_config.source }}
    - source_hash: {{ module_config.source_hash }}
    - user: {{ config.user }}
    - group: {{ config.group }}
    - mode: 644
    - require:
      - archive: {{ instance }}_geoserver_archive

{% else %}

{{ instance }}_jetty_module_{{ module }}:
  file.absent:
    - name: {{ module_config.name }}
{% endif %}

{% endif %}

##########
# CONFIG #
##########

{% if module_config.config is defined %}

{% if module_config.enabled %}

# Managed configuration files (if any)

{% if module_config.files is defined %}

{% for module_file_op, module_file_config in module_config.files.items() %}

{% if module_file_op == 'managed' %}

{% for conf_file_name, conf_file_params in module_file_config.items() %}

{{ instance }}_jetty_module_{{ module }}_{{ conf_file_name }}_file:
  file.managed:
    - name: {{ config.GEOSERVER_HOME | path_join(conf_file_name) }}
    - source: {{ conf_file_params.source }}
    - user: {{ config.user }}
    - group: {{ config.group }}
    - template: jinja
    - context:
        instance: {{ instance }}
    - mode: 640
    - require_in:
        - file: {{ instance }}_jetty_module_{{ module }}_config

{% endfor %}

{% elif module_file_op == 'recurse' %}

{% for conf_file_name, conf_file_params in module_file_config.items() %}

{{ instance }}_jetty_module_{{ module }}_{{ conf_file_name }}_file:
  file.recurse:
    - name: {{ config.GEOSERVER_HOME | path_join(conf_file_name) }}
    - source: {{ conf_file_params.source }}
    - user: {{ config.user }}
    - group: {{ config.group }}
    - clean: True
    - dir_mode: 755
    - file_mode: 644
    - require_in:
        - file: {{ instance }}_jetty_module_{{ module }}_config

{% endfor %}

{% endif %}  # module_file_op

{% endfor %}

{% endif %}  # module_config.files

# Management of .mod files

{{ instance }}_jetty_module_{{ module }}_config:
  file.managed:
    - name: {{ config.GEOSERVER_HOME | path_join('modules', module ~ '.mod') }}
    - contents: {{ module_config.config|yaml }}
    - user: {{ config.user }}
    - group: {{ config.group }}
    - mode: 644
    - require_in:
      - cmd: {{ instance }}_jetty_module_{{ module }}_ini

{% else %}

{{ instance }}_jetty_module_{{ module }}_config:
  file.absent:
    - name: {{ config.GEOSERVER_HOME | path_join('modules', module ~ '.mod') }}

{% endif %}

{% endif %}

#############
# start.ini #
#############

# XXX: https://github.com/saltstack/salt/issues/57223

{% if module_config.enabled %}
{{ instance }}_jetty_module_{{ module }}_ini:
  cmd.run:
    - name: {{ config.jdk_conf.JAVA_HOME | path_join('bin', 'java') }} -jar start.jar --add-to-start={{ module }}
    - cwd: {{ config.GEOSERVER_HOME }}
    - runas: {{ config.user }}
    - group: {{ config.group }}
    - shell: /bin/csh
    - env:
      - JAVA_HOME: {{ config.jdk_conf.JAVA_HOME }}
      - JAVA_OPTS: {{ config.jdk_conf.JAVA_OPTS }}

# --update-ini

{% if module_config.ini is defined %}

{% for ini_name, ini_value in module_config.ini.items() %}
{{ instance }}_jetty_module_{{ module }}_ini_{{ ini_name }}:
  cmd.run:
    - name: {{ config.jdk_conf.JAVA_HOME | path_join('bin', 'java') }} -jar start.jar --update-ini {{ ini_name }}={{ ini_value }}
    - cwd: {{ config.GEOSERVER_HOME }}
    - runas: {{ config.user }}
    - group: {{ config.group }}
    - shell: /bin/csh
    - env:
      - JAVA_HOME: {{ config.jdk_conf.JAVA_HOME }}
      - JAVA_OPTS: {{ config.jdk_conf.JAVA_OPTS }}
    - require:
      - cmd: {{ instance }}_jetty_module_{{ module }}_ini
{% endfor %}

{% endif %}


{% else %}
{{ instance }}_jetty_module_{{ module }}_ini:
  file.replace:
    - name: {{ config.GEOSERVER_HOME | path_join('start.ini') }}
    - pattern: ^--module={{ module }}$
    - repl: '#--module={{ module }}'
    - backup: False
{% endif %}


{% endfor %}
{% endfor %}
