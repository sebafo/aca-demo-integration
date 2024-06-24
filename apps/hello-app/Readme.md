# Build for Docker Hub
docker buildx build --platform linux/amd64 --tag sebafo/hello-container-app:v1 .
docker buildx build --platform linux/amd64 --tag sebafo/hello-container-app:v2 .

# Run App locally
node index.js