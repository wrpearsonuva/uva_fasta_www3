# Use a specific version of the Perl image based on Debian bookworm
FROM perl:bookworm

# Install any required system packages
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install CPAN modules
RUN cpanm install Your::Module

# Copy your application code
COPY .. /app
WORKDIR /app

# Define the command to run your Perl application
CMD ["perl", "your_app.pl"]






FROM nginx:bookworm
COPY .. /usr/share/nginx/html
MKDIR /usr/share/nginx/html/annot
COPY ../annot /usr/share/nginx/html/annot
EXPOSE 80
