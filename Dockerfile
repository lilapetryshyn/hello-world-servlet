FROM tomcat
COPY ./target/helloworld.war /usr/local/tomcat/webapps
EXPOSE 8000
