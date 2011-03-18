$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'session'

def inline_js_for(data)
  case data
  when Hash: '{' + data.map {|k,v| "#{k}:#{inline_js_for(v)}"}.join(',') + '}'
  when String: "'#{data}'"
  else data.to_s
  end
end

def creation_call(name, class_name, info)
  "#{name} = #{class_name}({\n" +
    info.keys.sort.map {|key| "\t#{key}:#{inline_js_for(info[key])}"}.join(",\n") + "\n});"
end

def js_sections_for(node)
  [creation_call(node.name, node.node_class.creation_call, node.properties)] +
    node.subviews.map {|child| [js_sections_for(child), "#{node.name}.add(#{child.name});"]}.flatten
end

def js_for(nodes)
  nodes.map {|node| js_sections_for(node)}.flatten.join("\n\n")
end

def js_comments_for text
  text.map {|line| line.chomp.empty? ? line : "// #{line}"}.join + "\n"
end
