require 'sketchup.rb'
require 'extensions.rb'

#Namespace
module JunctionBox 
    
    unless file_loaded?(__FILE__) #guard against the extension being loaded multiple times
    
    #Define extension
    ex = SketchupExtension.new('Create Junction Box', 'create_junction_box/main')   
    
    #Register Extension
    Sketchup.register_extension(ex, true) 
    file_loaded(__FILE__)
  end

end # module Examples    
