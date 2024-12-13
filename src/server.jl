using HTTP

# Define the HTML content
const HTML_CONTENT = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Julia Web Server</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
        }
    </style>
</head>
<body>
    <h1>Hello from Julia!</h1>
    <p>This page is served by a Julia HTTP server.</p>
</body>
</html>
"""

# Define the handler function for HTTP requests
function handler(req::HTTP.Request)
    return HTTP.Response(200, HTML_CONTENT)
end

# Start the server
function main()
    port = 8000
    server = HTTP.serve!(handler, "127.0.0.1", port)
    println("Server is running at http://127.0.0.1:$port")
    return server
end

# Run the server
main() 