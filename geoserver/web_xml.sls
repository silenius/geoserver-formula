{% from "geoserver/map.jinja" import geoserver with context %}

include:
  - geoserver.install


{% for instance, config in geoserver.instances.items() %}

{% if config.jndis is defined %}

{{ instance }}_geoserver_web_xml_JNDI:
  file.blockreplace:
    - name: {{ config.web_xml }}
    - marker_start: <!-- START managed_resource_ref -->
    - marker_end: <!-- END managed_resource_ref -->
    - content: |
        {%- for jndi_name, jndi_conf in config.jndis.items() %}
        <resource-ref>
          <description>{{ jndi_name }}</description>
          <res-ref-name>jdbc/{{ jndi_name }}</res-ref-name>
          <res-type>javax.sql.DataSource</res-type>
          <res-auth>Container</res-auth>
        </resource-ref>
        {%- endfor %}
    - require:
      - file: {{ instance }}_geoserver_web_xml

{% endif %}

{% endfor %}
