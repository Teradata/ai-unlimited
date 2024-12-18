#!/bin/bash

API_KEY=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 64)

# Set the value of the environment variable
export AI_UNLIMITED_INIT_API_KEY=$API_KEY

# Print the value of the environment variable
echo "API Key is generated, if the shell script is not run with source, please export the following environment variable:"
echo ''
echo "export AI_UNLIMITED_INIT_API_KEY=${API_KEY}"
