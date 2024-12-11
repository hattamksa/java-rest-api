# Stage 1: Base Image
FROM bellsoft/liberica-openjdk-alpine:17 as base
RUN apk update && apk add --no-cache \
    curl \
    iputils \
    tzdata \
    ca-certificates \
    openssl \
    wget \
    tar \
    busybox \
    && addgroup -S devops \
    && adduser -S devops -G devops \
    && mkdir -p /home/devops/app \
    && chown -R devops:devops /home/devops \
    && chmod -R 755 /home/devops \
    && rm -rf /var/cache/apk/*

# Stage 2: Maven Builder
FROM public.ecr.aws/docker/library/maven:3.9.8-amazoncorretto-17-debian-bookworm as basemaven
RUN groupadd -r devops && useradd -r -g devops devops \
    && mkdir -p /home/devops/app \
    && chown -R devops:devops /home/devops \
    && chmod -R 755 /home/devops

# Stage 3: Dependency Management
#FROM basemaven as dependency
#USER devops
#WORKDIR /home/devops/app
#COPY --chown=devops:devops .mvn .mvn
#COPY --chown=devops:devops pom.xml .
# Debug: Check if files are copied correctly
#RUN ls -la /home/devops/app

# Stage 4: Build Application
#FROM dependency as builder
FROM basemaven as builder
USER devops
WORKDIR /home/devops/app
COPY --chown=devops:devops . .
RUN mvn -U clean package

# Stage 5: Final Image
FROM base as artifact
LABEL maintainer="devsecops teams"
ENV TZ=Asia/Singapore
USER devops
WORKDIR /home/devops/app
COPY --from=builder /home/devops/app/target/*.jar /home/devops/app/app.jar
ENV JAVA_OPTS=""
EXPOSE 8080
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar /home/devops/app/app.jar"]
