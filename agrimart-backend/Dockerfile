# Use the official Node.js image as the base image
FROM node:18-alpine

# Set the working directory inside the container
WORKDIR /app

# Install OpenSSL (required for Prisma on Alpine Linux)
RUN apk add --no-cache openssl

# Copy package.json and package-lock.json first (to leverage Docker cache)
COPY package*.json ./

# Copy the prisma directory (needed for pre-install generation if applicable)
COPY prisma ./prisma/

# Install dependencies
RUN npm install

# Generate Prisma Client
RUN npx prisma generate

# Copy the rest of the application code
COPY . .

# Expose the port your app runs on (change if your app uses a different port)
EXPOSE 3000

# Start the application
CMD ["npm", "start"]
