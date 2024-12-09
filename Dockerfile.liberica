# Use OpenJDK as the base image
FROM bellsoft/liberica-openjdk-alpine:17

# Set the working directory inside the container
WORKDIR /app

# Copy the built jar file from the target directory to the container
COPY target/java-rest-api-1.0-SNAPSHOT.jar app.jar

# Expose port 8080 (default for Spring Boot)
EXPOSE 8080

# Command to run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
