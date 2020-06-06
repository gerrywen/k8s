FROM fiadliel/java8-jre
VOLUME /tmp
ADD mall-authentication-service-1.0.0-SNAPSHOT.jar  app.jar
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN echo 'Asia/Shanghai' >/etc/timezone
ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-jar","/app.jar"]