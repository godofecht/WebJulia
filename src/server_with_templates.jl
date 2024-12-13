using HTTP
using Metal

# Function to perform calculation on GPU
function calculate(num1::String, num2::String)
    try
        # Convert strings to numbers, default to 0 if empty
        n1 = isempty(num1) ? 0.0f0 : parse(Float32, num1)
        n2 = isempty(num2) ? 0.0f0 : parse(Float32, num2)
        
        # Simple CPU calculation first to verify inputs
        cpu_result = n1 * n2
        
        # If CPU calculation worked, try GPU
        try
            # Create smaller array for testing
            array_size = 100
            gpu_array1 = MtlArray(fill(n1, array_size))
            gpu_array2 = MtlArray(fill(n2, array_size))
            
            # Perform multiplication on GPU
            result = gpu_array1 .* gpu_array2
            
            # Convert result to host array and take first element
            host_result = Array(result)
            final_result = host_result[1]
            
            return final_result
        catch gpu_error
            println("GPU error: ", gpu_error)
            # Fallback to CPU result if GPU fails
            return cpu_result
        end
    catch e
        println("Calculation error: ", e)
        return "Error: Invalid calculation"
    end
end

# Function to read HTML template and inject calculation
function read_template(filename::String, req::HTTP.Request)
    try
        template = read(filename, String)
        
        # Parse query parameters if they exist
        uri = HTTP.URI(req.target)
        query = HTTP.queryparams(uri)
        
        num1 = get(query, "num1", "")
        num2 = get(query, "num2", "")
        
        result = calculate(num1, num2)
        
        # Replace placeholders with values
        template = replace(template, "{{RESULT}}" => result)
        template = replace(template, "{{NUM1}}" => num1)
        template = replace(template, "{{NUM2}}" => num2)
        
        return template
    catch e
        println("Template error: ", e)
        return """
        <!DOCTYPE html>
        <html><body>
        <h1>Error processing request</h1>
        <p>Please try again with valid numbers.</p>
        <a href="/">Back to calculator</a>
        </body></html>
        """
    end
end

# Define the handler function for HTTP requests
function handler(req::HTTP.Request)
    try
        uri = HTTP.URI(req.target)
        
        if uri.path == "/"
            template = read_template("templates/index.html", req)
            return HTTP.Response(200, template)
        elseif uri.path == "/calculate"
            # Handle AJAX calculation requests
            query = HTTP.queryparams(uri)
            num1 = get(query, "num1", "")
            num2 = get(query, "num2", "")
            result = calculate(num1, num2)
            return HTTP.Response(200, string(result))
        else
            return HTTP.Response(404, "Page not found")
        end
    catch e
        # Handle connection errors separately
        if isa(e, Base.IOError) && occursin("broken pipe", lowercase(e.msg))
            # Log the error but don't crash the server
            @warn "Client disconnected prematurely"
            return HTTP.Response(499, "Client Closed Request")  # 499 is a common code for this case
        end
        # Handle other errors
        @error "Server error" exception=(e, catch_backtrace())
        return HTTP.Response(500, "Internal Server Error")
    end
end

# Start the server
function main()
    initial_port = 8000
    max_attempts = 10
    
    for port in initial_port:(initial_port + max_attempts)
        try
            server = HTTP.serve(handler, "127.0.0.1", port)
            println("Server is running at http://127.0.0.1:$port")
            return server
        catch e
            if e isa Base.IOError && occursin("address already in use", lowercase(e.msg))
                println("Port $port is in use, trying next port...")
                continue
            end
            rethrow(e)
        end
    end
    error("Could not find an available port between $initial_port and $(initial_port + max_attempts)")
end

main() 