#!/bin/bash

# Check if Flask is installed
if python3 -c "import flask" &> /dev/null; then
    # Flask is installed, run the Python application
    sudo python3 app.py &
else
    echo "Flask is not installed. Skipping application execution."
fi