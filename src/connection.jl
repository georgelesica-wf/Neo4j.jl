export DEFAULT_HOST, DEFAULT_PORT, DEFAULT_URI, Connection,
       connurl, connheaders

const DEFAULT_HOST = "localhost"
const DEFAULT_PORT = 7474
const DEFAULT_URI = "/db/data/"

immutable Connection
  tls::Bool
  host::AbstractString #UTF8String
  port::Int
  path::AbstractString #UTF8String
  user::AbstractString #UTF8String
  password::AbstractString #UTF8String

  function Connection(host::AbstractString=DEFAULT_HOST;
      port::Int=DEFAULT_PORT,
      path::AbstractString=DEFAULT_URI, tls::Bool=false,
      user::AbstractString="", password::AbstractString="")
    pathprefix = ""
    if !startswith(path, "/")
      pathprefix = "/"
    end

    pathsuffix = ""
    if !endswith(path, "/")
      pathsuffix = "/"
    end

    fullpath = pathprefix * path * pathsuffix

    return new(tls, host, port, fullpath, user, password)
  end
end

function connurl(c::Connection)
  proto = ifelse(c.tls, "https", "http")
  return "$(proto)://$(c.host):$(c.port)$(c.path)"
end

function connurl(c::Connection, suffix::AbstractString)
  url = connurl(c)
  return "$(url)$(suffix)"
end

function connheaders(c::Connection)
  headers = Dict(
    "Accept" => "application/json; charset=UTF-8",
    "Host" => "$(c.host):$(c.port)")
  if c.user != "" && c.password != ""
    payload = "$(c.user):$(c.password)" |> base64encode
    headers["Authorization"] = "Basic $(payload)"
  end
  headers
end
