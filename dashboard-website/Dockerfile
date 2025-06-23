# Start with a Golang base image
FROM golang:1.22-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy the Go source code first
COPY main.go .

# Initialize the Go module and tidy it
# 'dashboard-website' is your module name - you can choose a more specific one if needed
RUN go mod init dashboard-website
RUN go mod tidy # This will generate go.sum and ensure go.mod is correct

# No need for 'go mod download' here, as 'go mod tidy' usually handles it,
# or 'go build' will download necessary modules if any actual external dependencies are added.

# Build the Go application
# CGO_ENABLED=0 disables CGO, making the binary statically linked and smaller
# -o app specifies the output binary name
# -ldflags="-s -w" removes debug information and symbol table, further reducing binary size
RUN CGO_ENABLED=0 go build -o app -ldflags="-s -w" main.go

# --- Start a new stage for a very small production image ---
FROM alpine:latest

# Set the working directory
WORKDIR /app

# Copy only the compiled Go application from the builder stage
COPY --from=builder /app/app .

# Create the assets directory inside the container
RUN mkdir -p assets

# Copy the HTML file from the host's 'assets' directory
# INTO the container's 'assets' directory
COPY assets/index.html ./assets/
COPY assets/video.html ./assets/

# Expose port 8080
EXPOSE 8080

# Command to run the application
CMD ["./app"]