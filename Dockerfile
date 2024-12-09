FROM bellsoft/liberica-openjdk-alpine:17 as base
RUN apk update \
    && apk -s upgrade \
    && apk add curl iputils tzdata ca-certificates openssl wget tar \
    && apk add --upgrade busybox \
    && apk add --upgrade curl iputils tzdata musl \
    && addgroup -S devops \
    && adduser -S devops -G devops \
    && mkdir -p /home/devops/app \
    && chown -R devops:devops /home/devops \
    && chown -R devops:devops /home/devops/app \
    && chmod -R 755 /home/devops \
    && rm -rf /var/cache/apk/*
# Set the working directory inside the container

FROM public.ecr.aws/docker/library/maven:3.9.8-amazoncorretto-17-debian-bookworm as basemaven
# COPY --from=8483738339392.dkr.ecr.ap-southeast-1.amazonaws.com/tools-devsecops:aws-cli-2-16-8-arm /usr/local/aws-cli /usr/local/aws-cli

## Create User and Group with default home directory
RUN groupadd -r devops && useradd -r -g devops devops \
    && mkdir -p /home/devops/app \
    && chown -R devops:devops /home/devops \
    && chown -R devops:devops /home/devops/app \
    && chmod -R 755 /home/devops

FROM basemaven as dependency
USER devops
WORKDIR /home/devops/app
    
COPY --chown=devops:devops .mvn .mvn
COPY --chown=devops:devops pom.xml .
    
    # Debug: Check if files are copied correctly
RUN ls -la /home/devops/app
    
#RUN mvn -Dinclude=com.demo -DresolutionFuzziness=groupId -Dverbose=true
    

# RUN mvn   -Dinclude=com.demo -DresolutionFuzziness=groupId -Dverbose=true


FROM dependency as builder
USER devops
WORKDIR /home/devops/app
COPY --chown=devops:devops . .

RUN mvn  -U clean package 

FROM base as artifact
LABEL maintainer="devsecops teams"
ENV TZ=Asia/Singapore

# COPY --from=public.ecr.aws/aws-cli/aws-cli:2.11.25 /usr/local/aws-cli /usr/local/aws-cli
# COPY --from=860454231727.dkr.ecr.ap-southeast-1.amazonaws.com/tools-devsecops:aws-cli-2-16-8-arm /usr/local/aws-cli /usr/local/aws-cli

# ENV PATH="/usr/local/aws-cli/v2/current/bin:${PATH}"

USER devops
WORKDIR /home/devops/app
COPY --from=builder /home/devops/app/target/*.jar /home/devops/app/app.jar

ENV JAVA_OPTS=""
EXPOSE 8080

ENTRYPOINT exec java $JAVA_OPTS -jar /home/devops/app/app.jar
