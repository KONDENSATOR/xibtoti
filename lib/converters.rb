# Converters converts data in the xib files property bag to the NodeInfos property bag.
# The output key it will have is stored here. The converter can be created with a conversion block
# Converter.new :output {|v| Convert value v here...}

class Converter
  def initialize(output, &conversion)
    @output = output
    @conversion = conversion || proc {|v| v}
  end
  
  def props_for(value)
    converted_value = @conversion.call(value)
    if converted_value
      {@output, converted_value}
    end
  end
end

# MultiConverter is used for cases when a property in the xhib file's property bag needs multiple
# properties in JS
# Example: {'frameOrigin' => "{123, 456}"} should give {:top => 123, :bottom => 456}
# Done by: MultiConverter.new([:top, :bottom], /\{(\d+), (\d+)\}/) {|v| v.to_i}

class MultiConverter < Converter
  def initialize(outputs, regex, &conversion)
    @outputs = outputs
    @regex = regex
    @conversion = conversion || proc {|v| v}
  end
  
  def props_for(value)
    if match = @regex.match(value)
      Hash[@outputs.zip(match.captures.map(&@conversion))]
    end
  end
end
