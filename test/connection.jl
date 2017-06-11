using Neo4j
using Base.Test

conn = Connection()
defaulturl = "http://$(DEFAULT_HOST):$(DEFAULT_PORT)$(DEFAULT_URI)"
@test connurl(conn) == defaulturl
@test connurl(conn, "suffix") == "$(defaulturl)suffix"

conn = Connection(tls=true)
@test startswith(connurl(conn), "https://")

conn = Connection(port=8888, path="database")
@test endswith(connurl(conn), "8888/database/")

conn = Connection("example.com", tls=true)
@test startswith(connurl(conn), "https://example.com")

conn = Connection(user="user", password="password")
headers = connheaders(conn)
auth = "user:password" |> base64encode
@test headers["Authorization"] == "Basic $(auth)"
@test headers["Host"] == "$(conn.host):$(conn.port)"
