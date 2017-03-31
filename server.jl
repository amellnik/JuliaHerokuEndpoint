tic()
using Mux, JSON, HttpCommon #Other packages go here

# Headers -- if this API will be called from a web site hosted on another domain
# you need to make sure you add it below.

devServer = "http://localhost:4200"
prodServer = "http://app.juliadiffeq.org"

function withHeaders(res, req)
    println("Origin: ", get(req[:headers], "Origin", ""))
    headers  = HttpCommon.headers()
    headers["Content-Type"] = "application/json; charset=utf-8"
    if get(req[:headers], "Origin", "") == devServer
        headers["Access-Control-Allow-Origin"] = devServer
    else
        headers["Access-Control-Allow-Origin"] = prodServer
    end
    println(headers["Access-Control-Allow-Origin"])
    Dict(
       :headers => headers,
       :body=> res
    )
end

# Better error handling
function errorCatch(app, req)
  try
    app(req)
  catch e
    println("Error occured!")
    io = IOBuffer()
    showerror(io, e)
    err_text = takebuf_string(io)
    println(err_text)
    resp = withHeaders(JSON.json(Dict("message" => err_text, "error" => true)), req)
    resp[:status] = 500
    return resp
  end
end

# A simple echo endpoint that accepts base64 encoded JSONs
function echo(req::Dict{Any,Any})
  # Grab everything following the base path as a string
  b64 = convert(String, req[:path][1])
  # Convert it from base64 to a normal string
  queryJSON = String(base64decode(b64))
  # Parse that JSON string into a Dict object
  queryDict = JSON.parse(queryJSON)

  println("Someone sent me this query: ", queryDict, " and we're going to send it right back to them with a slight modification!")

  # Add an additional property then return the input
  queryDict["Echo"] = "true"
  return JSON.json(queryDict)
end

# An endpoint that does a tiny bit of math and accepts a single number
# To pass multiple parameters you probably want to stick them in a JSON and
# encode it in a base64 string as in the example above.
function loglog(req::Dict{Any,Any})
  x = parse(Float64, req[:path][1])
  d = Dict("Input" => x, "Output" => log(log(x)))
  return JSON.json(d)
end

# We use the same middleware stack as Mux but with our error handler
ourStack = stack(Mux.todict, errorCatch, Mux.splitquery, Mux.toresponse)

@app app = (
    ourStack,
    page(req -> withHeaders("Nothing to see here...", req)),
    route("/echo", req -> withHeaders(echo(req), req)),
    route("/loglog", req -> withHeaders(loglog(req), req)),
    Mux.notfound()
)

# Prime the pumps by calling each function that we want to use once
echo(convert(Dict{Any,Any},Dict(:path=>["eyJNZXNzYWdlIjoiSGVsbG8hIn0="])))
loglog(convert(Dict{Any,Any},Dict(:path=>["3.1215"])))

println("Setting everything up took this long: ", toq())

println("About to start the server!")
@sync serve(app, port=parse(Int64, ARGS[1]))
