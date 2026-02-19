FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production=false
COPY . .
RUN npm run build

FROM nginx:alpine
# Security: Run as non-root user
RUN addgroup -g 1001 -S nginx_grp && adduser -u 1001 -S nginx_user -G nginx_grp
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost/ || exit 1
CMD ["nginx", "-g", "daemon off;"]
