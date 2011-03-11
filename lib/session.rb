require 'rubygems'
require 'plist'

# Stores all configurable info on how to translate the xib to JS
# The session is created from a config file.

class Session
  def initialize(path)
    @ignore_properties = []
    @ignore_classes = []
    @classes = {}
    @properties = {}
    @log = []
    File.open path do |file|
      eval file.read
    end
  end
  
  attr_reader :out
  
  def parse_file(file)
    data = Plist::parse_xml( %x[ibtool #{file} --hierarchy --objects --connections] )
    @out = data['com.apple.ibtool.document.hierarchy'].map {|hierarchy| NodeInfo.for hierarchy, data['com.apple.ibtool.document.objects'], self}.compact
    data['com.apple.ibtool.document.connections'].each do |connection|
      # TODO
    end
    @out
  end
  
  def full_log(severities=[])
    excluded = @log.map(&:first).uniq - severities
    (excluded.empty? ? '' : "There were log entries of severity: #{excluded.join ', '}\n") +
    @log.map do |severity, message|
      "[#{severity}] #{message}" if severities.include? severity
    end.compact.join("\n")
  end
  
  def has_errors?
    @log.any? {|severity, message| severity == :error}
  end
  
  def log(severity, message)
    @log.push [severity, message]
  end
  
  def ignore_class?(class_name)
    @ignore_classes.include? class_name
  end
  
  def ignore_property?(property_name)
    @ignore_properties.include? property_name
  end
  
  def converter_for(property_name)
    @properties[property_name]
  end
  
  def class_info_for(class_name)
    @classes[class_name]
  end
  
  def classes(class_hash)
    class_hash.each do |key, value|
      @classes[key] = ClassInfo.new(*value)
    end
  end
  
  def ignore_properties(*names)
    @ignore_properties += names
  end
  
  def ignore_classes(*names)
    @ignore_classes += names
  end
  
  def properties(properties_hash)
    @properties.merge! properties_hash
  end
  
  # Color helper methods

  def hex(v)
    "%02x" % (v.to_f*255).round
  end

  def rgba(r, g, b, a)
    "##{hex(r)}#{hex(g)}#{hex(b)}#{hex(a)}"
  end
  
  # Methods for converter creation in config file
  
  def val(name)
    Converter.new(name)
  end

  def bool(name)
    Converter.new(name) {|v| v==1}
  end

  def lookup(name, hash)
    Converter.new(name) {|v| hash[v]}
  end

  def color(name)
    Converter.new(name) do |v| 
      case v
      when /NS(?:Calibrated|Device)RGBColorSpace (\d+(?:\.\d+)?) (\d+(?:\.\d+)?) (\d+(?:\.\d+)?) (\d+(?:\.\d+)?)/
        rgba($1, $2, $3, $4)
      when /NS(?:Calibrated|Device)WhiteColorSpace (\d+(?:\.\d+)?) (\d+(?:\.\d+)?)/
        rgba($1, $1, $1, $2)
      when /NSCustomColorSpace Generic Gray colorspace (\d+(?:\.\d+)?) (\d+(?:\.\d+)?)/
        rgba($1, $1, $1, $2)
      end
    end
  end

  def font(name)
    Converter.new(name) do |v| 
      {:fontFamily => v['Family'], :fontSize => v['Size']}
    end
  end

  def vector(x, y)
    MultiConverter.new([x, y], /\{(\d+), (\d+)\}/) {|v| v.to_i}
  end
end
