#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'session'
require 'optparse'

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
  
usage = "Usage: xibtoti.rb [options] filename"
OptionParser.new do |opts|
  opts.banner = usage
  
  opts.on("-w", "--[no-]warnings", "Show warnings") do |w|
    @show_warnings = w
  end

  opts.on("-o", "--output-file name", "Specify output file") do |o|
    @output_file = o
  end
  
  opts.on("-c", "--config-file name", "Specify config file") do |o|
    @config_file = o
  end
  
end.parse!

if ARGV.size == 1
  input_file = ARGV.first
  session = Session.new @config_file || File.join(File.dirname(__FILE__), 'config.rb')
  session.parse_file input_file
  if session.has_errors?
    puts "Aborted!"
    puts session.full_log [:error]
  else  
    severities = []
    severities.unshift :warning if @show_warnings
    log = session.full_log severities
    script = js_comments_for(log) + js_for(session.out)
    if @output_file
      File.open(@output_file, 'w') do |file|
        file.write script
      end
      puts log
    else
      puts script
    end
  end
else
  puts "For help, type: xibtoti.rb -h"
end
