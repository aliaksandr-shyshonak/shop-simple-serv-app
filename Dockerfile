FROM node:20-alpine
WORKDIR /usr/src/app
COPY index.js package.json .
RUN npm install
EXPOSE 3000
ENTRYPOINT ["node", "index.js"]
