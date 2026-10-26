FROM gradle:8.14-jdk17 AS build
WORKDIR /src
COPY . .
RUN gradle --no-daemon bootJar -x test

FROM eclipse-temurin:17-jre
RUN useradd -r -u 1001 jemis
USER jemis
COPY --from=build /src/build/libs/*.jar /app/app.jar
EXPOSE 8080
HEALTHCHECK CMD wget -qO- http://localhost:8080/actuator/health/readiness || exit 1
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
