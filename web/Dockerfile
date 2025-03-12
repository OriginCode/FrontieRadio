# Build with NodeJS
FROM node:lts AS build
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm install

COPY . ./
RUN npm run build

# Deploy with nginx
FROM nginx:alpine AS deploy

COPY --from=build /app/build /usr/share/nginx/html/
