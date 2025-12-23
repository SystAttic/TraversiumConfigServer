FROM eclipse-temurin:17-jdk
MAINTAINER Traversium Developers
WORKDIR /opt/config-server

COPY target/*.jar app.jar
ENTRYPOINT ["java","-jar","/opt/config-server/app.jar"]
