{% from "geoserver/map.jinja" import geoserver with context %}

include:
  - geoserver.plugins

{% for instance, config in geoserver.instances.items() %}
{% if config.clustering.enabled %}
{{ instance }}_geoserver_cluster_properties:
  file.managed:
    - name: {{ config.clustering.config.CLUSTER_CONFIG_DIR | path_join('cluster.properties') }}
    - contents: |
        {%- for cl_name, cl_value in config.clustering.config.items() %}
        {{ cl_name }}={{ cl_value }} 
        {%- endfor %}
    - user: {{ config.user }}
    - group: {{ config.group }}
    - mode: 644
    - makedirs: True
    - require:
      - archive: {{ instance }}_geoserver_plugin_jms-cluster
{% endif %}
{% endfor %}
