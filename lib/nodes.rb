# NodeInfo contains the information from the xib, both hierarchy and properties

class NodeInfo
  def initialize(name, node_id, node_class, subviews)
    @name = name
    @node_id = node_id
    @node_class = node_class
    @subviews = subviews
    @properties = {}
  end

  attr_reader :properties, :name, :node_class, :subviews
  
  def self.enumerate(name)
    "#{name}#{(@@name_counters ||= Hash.new {0})[name]+=1}"
  end

  def self.for(hierarchy, data, session)
    id = hierarchy['object-id'].to_s
    info = data[id]
    node_class = session.class_info_for info['class']
    if node_class  
      name = hierarchy['name'] || enumerate(node_class.name.downcase)
      subviews = (hierarchy['children'] || []).map {|child_hierarchy| NodeInfo.for(child_hierarchy, data, session)}.compact
      node = NodeInfo.new name, id, node_class, subviews
      info.each do |prop, value|
        if converter = session.converter_for(prop)
          props = converter.props_for(value)
          if props
            node.properties.merge! props
          else
            session.log(:error, "Could not convert #{prop}: #{value}")
          end
        else
          session.log(:warning, "Skipped property for #{info['class']}: #{prop}") unless session.ignore_property? prop
        end
      end
      node
    else
      session.log(:warning, "Skipped class #{info['class']}")  unless session.ignore_class? info['class']
    end
    node
  end
end

# ClassInfo contains all known information on the class of the node info (Windows, Views... etc)

class ClassInfo
  def initialize(name, creation_call="Ti.UI.create#{name}")
    @name = name
    @creation_call = creation_call
  end
  
  attr_reader :name, :creation_call
end

