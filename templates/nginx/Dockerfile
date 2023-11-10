FROM nginx:{{nginx_image_tag}}
ADD https://github.com/open-telemetry/opentelemetry-cpp-contrib/releases/download/webserver%2Fv1.0.3/opentelemetry-webserver-sdk-x64-linux.tgz /opt
RUN cd /opt && tar xvfz opentelemetry-webserver-sdk-x64-linux.tgz
RUN cd /opt/opentelemetry-webserver-sdk && ./install.sh && cp /opt/opentelemetry-webserver-sdk/WebServerModule/Nginx/{{nginx_image_tag}}/ngx_http_opentelemetry_module.so /etc/nginx/modules
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/opentelemetry-webserver-sdk/sdk_lib/lib
