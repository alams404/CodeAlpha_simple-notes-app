# base image using alpine linux
FROM node:20-alpine

# set working directory
WORKDIR /app

# copy the current directory contents into the container 
COPY . .

# install dependencies 
COPY package.json ./
RUN npm install

# expose port 3000
EXPOSE 3000

# run the command to start the application
CMD ["npm", "start"]
