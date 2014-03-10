require 'csv'


def inverse_exists relationship, pairs
  return pairs.include? "#{relationship.related_id},#{relationship.node_id}"
end

def find_missing relationship
end

def links_csv
  pairs = []
  symbols = []
  bads = []
  OMS::Relationship.all.each do |r|
    if !inverse_exists r
      pairs.push("#{r.node_id},#{r.related_id}")

      if OMS::Node.where(id: r.node_id).length > 0 && OMS::Node.where(id: r.related_id).length > 0
        # puts "#{r.node.id} <---> #{r.related.id}"
        symbols.push( {id1: r.node.id, name1: r.node.name, id2: r.related.id, name2: r.related.name} )
      else
        bads.push("----- #{r.node_id} <---> #{r.related_id}")
        # puts "----- #{r.node_id} <---> #{r.related_id}"
      end
    end
  end

  # puts symbols.length
  # puts bads.length

  csv_string = CSV.generate do |csv|
    csv << ["id1", "name1", "id2", "name2"]
    symbols.each do |s|
      csv << [s[:id1],s[:name1],s[:id2],s[:name2]]
    end
  end

  puts csv_string
end

def node_weight node
  return node.relationships.length #collect{|r| r.weight+4}.sum
end


def force_directed
  nodes = []
  links = []
  pairs = []
  OMS::Node.all.each do |n|
    nodes.push({name: n.name, id: n.id, group: n.node_type.id, radius: node_weight(n), color:n.node_type.color})
    puts n.id
    n.relationships.each do |r|
      if !inverse_exists r, pairs
        pairs.push("#{r.node_id},#{r.related_id}")
        links.push({source: r.node_id, target: r.related_id, weight: (r.weight+3)})
      end
    end
  end
  output = {nodes: nodes, links: links}
  File.open("../viz/vuz.json","w") do |f|
    f.write(output.to_json)
  end
end


def force_directed_groups
  nodes = []
  links = []
  pairs = []
  groups = 1
  OMS::Node.limit(300).each do |n|
    nodes.push({name: n.name, id: n.id, group: groups})
    groups = groups+1
    n.relationships.each do |r|
      if !inverse_exists r, pairs
        pairs.push("#{r.node_id},#{r.related_id}")
        links.push({source: r.node_id, target: r.related_id, weight: (r.weight+3)})
      end
    end
  end
  output = {nodes: nodes, links: links}
  puts output.to_json
end

def per_node
  OMS::Node.all.each do |n|
    nodes = []
    links = []
    nodes.push({name: n.name, id: n.id, group: n.node_type.id, radius: node_weight(n), color:n.node_type.color})
    puts n.id
    n.relationships.each do |r|
      if OMS::Node.where(id: r.node_id).length > 0 && OMS::Node.where(id: r.related_id).length > 0
        related = r.related
        nodes.push({name: related.name, id: related.id, group: related.node_type.id, radius: node_weight(related)})
        links.push({source: n.id, target: r.related_id, weight: (r.weight+3)})
      end
    end
    output = {nodes: nodes, links: links}
    File.open("../viz/nodes/#{n.id}.json","w") do |f|
      f.write(output.to_json)
    end
  end

end

per_node
