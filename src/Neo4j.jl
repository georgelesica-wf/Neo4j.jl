module Neo4j

using Requests
using JSON

export getgraph, version, createnode, getnode, deletenode, setnodeproperty, getnodeproperties,
       updatenodeproperties, deletenodeproperties, deletenodeproperty, addnodelabel,
       addnodelabels, updatenodelabels, deletenodelabel, getnodelabels, getnodesforlabel,
       getlabels

const DEFAULT_HOST = "localhost"
const DEFAULT_PORT = 7474
const DEFAULT_URI = "/db/data/"
const DEFAULT_HEADERS = {"Accept" => "application/json; charset=UTF-8", "Host" => "localhost:7474"}

typealias JSONObject Union(Dict{String,Any},Nothing)
typealias JSONArray Union(Vector,Nothing)
typealias JSONData Union(JSONObject,JSONArray,String,Number,Nothing)

typealias QueryData Union(Dict{Any,Any},Nothing)

# ----------
# Connection
# ----------

immutable Connection
    host::String
    port::Int
    path::String
    url::String

    Connection(host::String, port::Int, path::String) = new(host, port, path, "http://$host:$port$path")
end

Connection(host::String, port::Int) = Connection(host, port, DEFAULT_URI)
Connection(host::String) = Connection(host, DEFAULT_PORT)
Connection() = Connection(DEFAULT_HOST)

# -----
# Graph
# -----

immutable Graph
    # TODO extensions
    node::String
    node_index::String
    relationship_index::String
    extensions_info::String
    relationship_types::String
    batch::String
    cypher::String
    indexes::String
    constraints::String
    transaction::String
    node_labels::String
    version:: String
    connection::Connection
end

Graph(data::Dict{String,Any}, conn::Connection) = Graph(data["node"], data["node_index"], data["relationship_index"],
    data["extensions_info"], data["relationship_types"], data["batch"], data["cypher"], data["indexes"],
    data["constraints"], data["transaction"], data["node_labels"], data["neo4j_version"], conn)

function getgraph(conn::Connection)
    resp = get(conn.url; headers=DEFAULT_HEADERS)
    if resp.status !== 200
        error("Connection to server unsuccessful: $(resp.status)")
    end
    Graph(resp.data |> JSON.parse, conn)
end

function getgraph()
    getgraph(Connection())
end

# ----
# Node
# ----

immutable Node
    # TODO extensions
    paged_traverse::String
    labels::String
    outgoing_relationships::String
    traverse::String
    all_typed_relationships::String
    all_relationships::String
    property::String
    self::String
    outgoing_typed_relationships::String
    properties::String
    incoming_relationships::String
    incoming_typed_relationships::String
    create_relationship::String
    data::Dict{String,Any}
    id::Int
    graph::Graph
end

Node(data::Dict{String,Any}, graph::Graph) = Node(data["paged_traverse"], data["labels"],
     data["outgoing_relationships"], data["traverse"], data["all_typed_relationships"],
     data["all_relationships"], data["property"],
     data["self"], data["outgoing_typed_relationships"], data["properties"],
     data["incoming_relationships"], data["incoming_typed_relationships"],
     data["create_relationship"], data["data"],
     split(data["self"], "/")[end] |> int, graph)

# --------
# Requests
# --------

function request(url::String, method::Function, exp_code::Int;
                 headers::Dict{Any,Any}=DEFAULT_HEADERS, json::JSONData=nothing,
                 query::QueryData=nothing)
    if json == nothing && query == nothing
        resp = method(url; headers=headers)
    elseif json == nothing
        resp = method(url; headers=headers, query=query)
    elseif query == nothing
        resp = method(url; headers=headers, json=json)
    else
        # TODO Figure out if this should ever occur and change it to an error if not
        resp = method(url; headers=headers, json=json, query=query)
    end
    if resp.status !== exp_code
        if resp.data !== ""
            respdata = resp.data |> JSON.parse
            error("Neo4j error: $(respdata["message"])")
        else
            error("Neo4j error: $(url) returned $(resp.status)")
        end
    end
    resp
end

# -----------------
# External requests
# -----------------

function createnode(graph::Graph, props::JSONData=nothing)
    resp = request(graph.node, post, 201; json=props)
    Node(resp.data |> JSON.parse, graph)
end

function getnode(graph::Graph, id::Int)
    url = "$(graph.node)/$id"
    resp = request(url, get, 200)
    Node(resp.data |> JSON.parse, graph)
end

function getnode(node::Node)
    getnode(node.graph, node.id)
end

function deletenode(node::Node)
    request(node.self, delete, 204)
end

function deletenode(graph::Graph, id::Int)
    node = getnode(graph, id)
    deletenode(node)
end

function setnodeproperty(node::Node, name::String, value::Any)
    url = replace(node.property, "{key}", name)
    request(url, put, 204; json=value)
end

function setnodeproperty(graph::Graph, id::Int, name::String, value::Any)
    node = getnode(graph, id)
    setnodeproperty(node, name, value)
end

function updatenodeproperties(node::Node, props::JSONObject)
    resp = request(node.properties, put, 204; json=props)
end

function getnodeproperties(node::Node)
    resp = request(node.properties, get, 200)
    resp.data |> JSON.parse
end

function getnodeproperties(graph::Graph, id::Int)
    node = getnode(graph, id)
    getnodeproperties(node)
end

function deletenodeproperties(node::Node)
    request(node.properties, delete, 204)
end

function deletenodeproperty(node::Node, name::String)
    url = replace(node.property, "{key}", name)
    request(url, delete, 204)
end

function addnodelabel(node::Node, label::String)
    request(node.labels, post, 204; json=label)
end

function addnodelabels(node::Node, labels::JSONArray)
    request(node.labels, post, 204; json=labels)
end

function updatenodelabels(node::Node, labels::JSONArray)
    request(node.labels, put, 204; json=labels)
end

function deletenodelabel(node::Node, label::String)
    url = "$(node.labels)/$label"
    request(url, delete, 204)
end

function getnodelabels(node::Node)
    resp = request(node.labels, get, 200)
    resp.data |> JSON.parse
end

function getnodesforlabel(graph::Graph, label::String, props::JSONObject=nothing)
    # TODO Shouldn't this url be available in the api somewhere?
    url = "$(graph.connection.url)label/$label/nodes"
    resp = request(url, get, 200; query=props)
    [Node(nodedata, graph) for nodedata = JSON.parse(resp.data)]
end

function getlabels(graph::Graph)
    resp = request(graph.node_labels, get, 200)
    resp.data |> JSON.parse
end

end # module
