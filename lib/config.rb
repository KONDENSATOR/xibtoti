ignore_properties 'contentStretch', 'simulatedStatusBarMetrics', 'simulatedOrientationMetrics'
ignore_classes 'IBProxyObject'

# To get another creation call than standard
# Ti.UI.create#{name}
# give a array as value: 'IBUIWindow' => ['Window', 'myWindowCall']
classes 'IBUIWindow' => 'Window',
        'IBUIView' => 'View',
        'IBUILabel' => 'Label',  
        'IBUIButton' => 'Button'

# Available types: 
# val(:output)
# bool(:output) # Where '0'=> {:output => false}, '1'=>{:output => true}
# lookup(:output, {'yes' => true, 'no' => false})
# color(:output)
# font(:output)
# vextor(:x, :y) # Where '{1, 2}' => {:x => 1, :y => 2}
properties 'backgroundColor' => color(:backgroundColor),
           'font' => font(:font),
           'frameOrigin' => vector(:top, :bottom),
           'frameSize' => vector(:height, :width),
           'text' => val(:text),
           'textColor' => color(:color)
