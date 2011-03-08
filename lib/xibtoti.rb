require 'rubygems'
require 'plist'
require 'pp'

LOG = [:error]

def log(type, message)
  puts "[#{type}] #{message}" if LOG.include? type
end

class Converter
  def initialize(output, &conversion)
    @output = output
    @conversion = conversion || proc {|v| v}
  end
  
  def props_for(value)
    {@output, @conversion.call(value)}
  end
end

class MultiConverter < Converter
  def initialize(outputs, regex, &conversion)
    @outputs = outputs
    @regex = regex
    @conversion = conversion || proc {|v| v}
  end
  
  def props_for(value)
    if match = @regex.match(value)
      Hash[@outputs.zip(match.captures.map(&@conversion))]
    else
      log(:error, "Malformed value #{value}")
      nil
    end
  end
end

# Color helper functions

def hex(v)
  "%02x" % (v.to_f*255).round
end

def rgba(r, g, b, a)
  "##{hex(r)}#{hex(g)}#{hex(b)}#{hex(a)}"
end

# Convertion helper functions

def val(name)
  Converter.new(name)
end

def bool(name)
  Converter.new(name) {|v| v==1}
end

def lookup(name, hash)
  Converter.new(name) {|v| hash[v] || log(:error, "Value #{v} not in lookup table")}
end

def color(name)
  Converter.new(name) do |v| 
    case v
    when /NS(?:Calibrated|Device)RGBColorSpace (\d+(?:\.\d+)?) (\d+(?:\.\d+)?) (\d+(?:\.\d+)?) (\d+(?:\.\d+)?)/
      rgba($1, $2, $3, $4)
    when /NS(?:Calibrated|Device)WhiteColorSpace (\d+(?:\.\d+)?) (\d+(?:\.\d+)?)/
      rgba($1, $1, $1, $2)
    else
      log(:error, "Unknown color #{v}")
    end
  end
end

def font(name)
  Converter.new(name) do |v| 
    {:fontFamily => v['Family'], :fontSize => v['Size']}
  end
end

def multi_int(names, regex)
  MultiConverter.new(names, regex) {|v| v.to_i}
end

# Configuration

CLASSES = {
  'IBUIWindow' => 'kwindow',
  'IBUIView' => 'kview',
  'IBUILabel' => 'klabel',  
  'IBUIButton' => 'kbutton',  
}

IGNORE_PROPS = %w{contentStretch simulatedStatusBarMetrics simulatedOrientationMetrics}

IGNORE_CLASSES = %w{IBProxyObject}

PROPS = {
  #'adjustsFontSizeToFitWidth' => bool(:adjustsFontSizeToFitWidth),
  #'alpha' => val(:alpha),
  #'alphaValue' => val(:alphaValue),
  #'autoresizesSubviews' => bool(:autoresizesSubviews),
  'backgroundColor' => color(:backgroundColor),
  'class' => lookup(:class, CLASSES),
  #'clipsSubviews' => bool(:clips),
  #'enabled' => bool(:enabled),
  'font' => font(:font),
  'frameOrigin' => multi_int([:height, :width], /\{(\d+), (\d+)\}/),
  'frameSize' => multi_int([:top, :left], /\{(\d+), (\d+)\}/),
  #'hidden' => bool(:hidden),
  #'highlightedColor' => color(:textColor),
  #'minimumFontSize' => val(:minimumFontSize),
  #'multipleTouchEnabled' => bool(:multipleTouchEnabled),
  'numberOfLines' => val(:numberOfLines),
  #'opaqueForDevice' => bool(:opaqueForDevice),
  #'resizesToFullScreen' => bool(:resizesToFullScreen),
  #'tag' => val(:tag),
  'text' => val(:text),
  'textColor' => color(:color),
  #'userInteractionEnabled' => bool(:userInteractionEnabled),
  #'visibleAtLaunch' => bool(:visibleAtLaunch),
}

# Counters for nodes

NAME_COUNTERS = Hash.new {0}

def enumerate(name)
  "#{name}#{NAME_COUNTERS[name]+=1}"
end

# Node creation

def node(hierarchy, data)
  out = {}
  hierarchy.each do |level| 
    id = level['object-id'].to_s
    info = data[id]
    if CLASSES.keys.include? info['class']  
      properties = {}
      properties[:subviews] = node(level['children'], data) if level['children']
      properties[:name] = level['name'] if level['name']
      info.each do |prop, value| 
        if PROPS[prop]
          properties.merge! PROPS[prop].props_for(value)
        else
          log(:warning, "Skipped property for #{info['class']}: #{prop}") unless IGNORE_PROPS.include? prop
        end
      end
      out[id] = properties
    else
      log(:warning, "Skipped class #{info['class']}")  unless IGNORE_CLASSES.include? info['class']
    end
  end
  out  
end

def parse_file(file)
  data = Plist::parse_xml( %x[ibtool #{file} --hierarchy --objects --connections] )
  out = node data['com.apple.ibtool.document.hierarchy'], data['com.apple.ibtool.document.objects']
  data['com.apple.ibtool.document.connections'].each do |connection|
    # TODO
  end
  out
end

def inline_js_for(data)
  if data.is_a? Hash
    '{' + data.map {|k,v| "#{k}:#{inline_js_for(v)}"}.join(',') + '}'
  elsif data.is_a? String
    "'#{data}'"
  else
    data.to_s
  end
end

def creation_call(name, class_name, info)
  "#{name} = #{class_name}({\n" +
    info.map {|key, value| "\t#{key}:#{inline_js_for(value)}"}.join(",\n") + "\n});"
end

def js_for(data, parent=nil)
  return nil unless data
  data.values.map do |subdata|
    info = subdata.clone
    subviews = info.delete(:subviews)
    class_name = info.delete(:class)
    name = info.delete(:name) || enumerate(class_name)
    [creation_call(name, class_name, info)] +
    [parent ? "#{parent}.add(#{name});" : nil] +
    [js_for(subviews, name)]
  end.flatten.compact.join("\n\n")
end

ARGV.each do |a|
  puts js_for(parse_file(a))
end

# out = parse_file 'test.xib'
# puts js_for(out)
