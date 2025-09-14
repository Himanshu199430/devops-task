# Use lightweight Node.js image
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy only package files and install dependencies first (caching)
COPY package*.json ./
RUN npm ci --only=production

# Copy the rest of the application code
COPY . .

# Expose app port
EXPOSE 3000

# Start the application
CMD ["npm", "start"]
