require 'sketchup.rb'
require 'csv'

module JunctionBox 

# Function to extrude any size rectangle in the vertical direction
def JunctionBox.extrudeRect(x1, y1, x2, y2, z, extrudeDepth, rectGroup)
  points = [
    Geom::Point3d.new(x1,y1,z),
    Geom::Point3d.new(x2,y1,z),
    Geom::Point3d.new(x2,y2,z),
    Geom::Point3d.new(x1,y2,z)
  ]
  face = rectGroup.entities.add_face(points)
  face.pushpull(extrudeDepth)
end

# Function to extrude any size cylinder in the horizontal direction from a point in an angle
def JunctionBox.extrudeCyl(x1, y1, z1, diameter, theta, extrudeDepth, cylGroup)
  center_point = Geom::Point3d.new(x1, y1, z1)
  normal_vector = Geom::Vector3d.new(Math.sin(theta), Math.cos(theta), 0)
  radius = (diameter / 2)

  hole_outer = cylGroup.entities.add_circle(center_point, normal_vector, radius)
  face = cylGroup.entities.add_face(hole_outer)
  face.pushpull(-extrudeDepth)
end

# Main junction box creation function
def JunctionBox.main(fileDir, jbName, topElevation, xIterationOffset, yIterationOffset, 
                    baseWidth, baseDepth, baseHeight, 
                    boxWidth, boxDepth, boxHeight, boxThickness, 
                    lidHoleWidth, lidHoleDepth, lidHeight, 
                    holeValues)
  
  elevationOffset = (topElevation * 12) - lidHeight - boxHeight - baseHeight                  
  
  # Make Base
  model = Sketchup.active_model
  #model.start_operation('Create JB Box', true)
  $group = model.active_entities.add_group
  $group.name = jbName
  entities = $group.entities  
  $box = entities.add_group

  if baseWidth != 0 && baseDepth != 0 && baseHeight != 0  
    extrudeRect(xIterationOffset, 0 + yIterationOffset, 
                baseWidth + xIterationOffset, baseDepth + yIterationOffset, 
                0 + elevationOffset, baseHeight, $box)
  else
    baseWidth = boxWidth
    baseDepth = boxDepth
    baseHeight = 0.1
  end

  # Make Box 
  if boxWidth != 0 && boxDepth != 0 && boxHeight != 0  

    widthOffset = (baseWidth-boxWidth) / 2
    depthOffset = (baseDepth-boxDepth) / 2
    
    # Box outer rectangle
    extrudeRect(widthOffset + xIterationOffset, depthOffset + yIterationOffset,
                widthOffset + boxWidth + xIterationOffset, depthOffset + boxDepth + yIterationOffset,
                baseHeight + elevationOffset,boxHeight, $box)
    # Remove box inner rectangle
    extrudeRect(widthOffset + boxThickness + xIterationOffset, depthOffset + boxThickness + yIterationOffset,
                widthOffset + boxWidth - boxThickness + xIterationOffset, depthOffset + boxDepth - boxThickness + yIterationOffset,
                baseHeight + boxHeight + elevationOffset, -boxHeight, $box)
    # Add Pipe Holes
    # hole_punch = entities.add_group
    # for i in 0..(holeValues.length - 1) do    

    #   holeAngle = holeValues[i][0].to_f
    #   holeUp = holeValues[i][1].to_f
    #   holeOffset = holeValues[i][2].to_f
    #   holeHeight = holeValues[i][3].to_f    
      
    #   theta = holeAngle * Math::PI / 180
      
    #   # 0 deg wall
    #   if (holeAngle >= 0 && holeAngle <= 45) || (holeAngle >= 315 && holeAngle <= 360) 
    #     angleOffset = (1.5 * boxThickness) * Math.tan(theta)
    #     center_point = Geom::Point3d.new(widthOffset + (boxWidth / 2) - angleOffset + holeOffset + xIterationOffset,depthOffset - boxThickness + yIterationOffset, baseHeight + holeUp + (holeHeight / 2))    
      
    #   # 90 deg wall
    #   elsif holeAngle > 45 && holeAngle <= 135
    #     angleOffset = (1.5 * boxThickness) * Math.tan(theta - (Math::PI / 2))
    #     center_point = Geom::Point3d.new(widthOffset - boxThickness + xIterationOffset,depthOffset + (boxDepth / 2) + angleOffset - holeOffset + yIterationOffset, baseHeight + holeUp + (holeHeight / 2))    

    #   # 180 deg wall
    #   elsif holeAngle > 135 && holeAngle <= 225
    #     angleOffset = (1.5 * boxThickness) * Math.tan(theta)
    #     center_point = Geom::Point3d.new(widthOffset + (boxWidth / 2) + angleOffset - holeOffset + xIterationOffset,depthOffset + boxDepth + boxThickness + yIterationOffset, baseHeight + holeUp + (holeHeight / 2))  

    #   # 270 deg wall
    #   elsif holeAngle > 225 && holeAngle < 315
    #     angleOffset = (1.5 * boxThickness) * Math.tan(theta - (Math::PI / 2))
    #     center_point = Geom::Point3d.new(widthOffset + boxWidth + boxThickness + xIterationOffset,depthOffset + (boxDepth / 2) - angleOffset + holeOffset + yIterationOffset, baseHeight + holeUp + (holeHeight / 2))      

    #   end

    #   normal_vector = Geom::Vector3d.new(Math.sin(theta),Math.cos(theta),0)
    #   radius = (holeHeight / 2)
      
    #   # Create solid pipes
    #   hole_outer = hole_punch.entities.add_circle(center_point, normal_vector, radius)
    #   face = hole_punch.entities.add_face(hole_outer)
    #   face.pushpull(4 * boxThickness)
    # end
    # Remove pipe hole from box
    # hole_punch.subtract($box)  
  end
    
  $hole_punch = entities.add_group
  for i in 0..(holeValues.length - 1) do 
    pipeAngle = holeValues[i][0].to_f
    holeUp = holeValues[i][1].to_f
    holeOffsetX = holeValues[i][2].to_f
    holeOffsetY = holeValues[i][3].to_f
    holeDiameter = holeValues[i][4].to_f 

    # Calculate the center point coordinates of the pipe
    theta = pipeAngle * Math::PI / 180

#    if holeOffsetX == 0 && holeOffsetY == 0
    if holeOffsetY == 0 # Top or Bottom wall
      #edge point x value
      if holeOffsetX < 0 # offset from right wall
        xEdge = xIterationOffset + widthOffset + boxWidth + holeOffsetX
        dir = -90
      elsif holeOffsetX > 0 # offset from left wall
        xEdge = xIterationOffset + widthOffset + holeOffsetX
        dir = 90
      else # 0 offset
        xEdge = xIterationOffset + widthOffset + boxThickness
        dir = 90
      end

      #edge point y value
      if pipeAngle < 90 || pipeAngle > 270 # top wall
        yEdge = yIterationOffset + depthOffset + boxWidth
        alpha = (pipeAngle + dir) * Math::PI / 180
      elsif pipeAngle > 89 && pipeAngle < 271 #bottom wall
        yEdge = yIterationOffset + depthOffset
        alpha = (pipeAngle - dir) * Math::PI / 180
      end

      #find center point from edge point
      xCenter = xEdge + (Math.sin(alpha) * (holeDiameter / 2))
      yCenter = yEdge + (Math.cos(alpha) * (holeDiameter / 2))
      zCenter = elevationOffset + baseHeight + holeUp + (holeDiameter / 2)
      
      


    elsif holeOffsetX == 0 # Left or Right wall
      if holeOffsetY < 0 # offset from Top wall

      elsif holeOffsetY > 0 # offset from Bottom wall

      else # 0 offset
        
      end
    else # corner

    end

    extrudeCyl(xCenter, yCenter, zCenter, holeDiameter, theta, (boxThickness * 3), $hole_punch)

  end

  $hole_punch.subtract($box)

  # Make Lid
  if lidHoleWidth != 0 && lidHoleDepth != 0 && lidHeight != 0   ### -- TODO: Deal with blank cells -- ###
    #model.commit_operation
    model = Sketchup.active_model
    #model.start_operation('Create JB Lid', true)
 
    widthOffset = (baseWidth-boxWidth) / 2
    depthOffset = (baseDepth-boxDepth) / 2

    # full lid rectangle
    extrudeRect(widthOffset + xIterationOffset, depthOffset + yIterationOffset,
                widthOffset + boxWidth + xIterationOffset, depthOffset + boxDepth + yIterationOffset,
                baseHeight + boxHeight + elevationOffset, lidHeight, $group)

    lidWidthOffset = ((boxWidth - (2 * boxThickness)) - lidHoleWidth) / 2
    lidDepthOffset = ((boxDepth - (2 * boxThickness)) - lidHoleDepth)

    # remove lid hole
    extrudeRect(widthOffset + boxThickness + lidWidthOffset + xIterationOffset, depthOffset + boxThickness + lidDepthOffset + yIterationOffset,
                widthOffset + boxWidth - boxThickness - lidWidthOffset + xIterationOffset, depthOffset + boxDepth - boxThickness + yIterationOffset,
                baseHeight + boxHeight + elevationOffset, -lidHeight, $group)
  end

  # create and save component
  comp = model.entities.add_group($group).to_component
  comp.name = jbName
  compPath = File.join(fileDir, jbName + ".skp")
  compdef = comp.definition
  compdef.save_as(compPath)
  #model.commit_operation  
end

toolbar = UI::Toolbar.new "Junction Box"
cmd = UI::Command.new("Batch Create CSV") {
# Select and read file
file = UI.openpanel('CSV File', 'c:\\')
#fileFormat = UI.inputbox(["Which format is your file in? \n1: \n2: \n3:"])
table = CSV.read(file)
boxNum = table.length
# Create component save directory
pathName = file.to_s
basename = File.basename(file, ".csv").to_s
pathName.slice!(File.basename(file).to_s)
fileDir = pathName + basename
unless File.directory?(fileDir)
  Dir.mkdir(fileDir)
end

xIterationOffset = 0
yIterationOffset = 0

# Create each box
for i in 1..(boxNum - 1) do
  # Identify variables
  jbName = table[i][0]
  topElevation = table[i][1].to_f
  baseWidth = table[i][2].to_f
  baseDepth = table[i][3].to_f
  baseHeight = table[i][4].to_f
  
  boxWidth = table[i][5].to_f
  boxDepth = table[i][6].to_f
  boxHeight = table[i][7].to_f
  boxThickness = table[i][8].to_f
  
  lidHoleWidth = table[i][9].to_f
  lidHoleDepth = table[i][10].to_f
  lidHeight = table[i][11].to_f
  
  holeInputs = 5
  numHoles = (table[i].length - 12) / holeInputs
  holeValues = []
  for n in 0..(numHoles-1) do
    unless table[i][12+(n*holeInputs)].to_f == 0 && table[i][13+(n*holeInputs)].to_f == 0 && table[i][14+(n*holeInputs)].to_f == 0 && table[i][15+(n*holeInputs)].to_f == 0 && table[i][16+(n*holeInputs)].to_f == 0
      holeValues = [[table[i][12+(n*holeInputs)].to_f, table[i][13+(n*holeInputs)].to_f, table[i][14+(n*holeInputs)].to_f, table[i][15+(n*holeInputs)].to_f, table[i][16+(n*holeInputs)].to_f]].unshift(*holeValues)
    end
  end

  # Make junction box
  main(fileDir, jbName, topElevation, xIterationOffset, yIterationOffset, 
        baseWidth, baseDepth, baseHeight, 
        boxWidth, boxDepth, boxHeight, boxThickness, 
        lidHoleWidth, lidHoleDepth, lidHeight, 
        holeValues)
  
  xIterationOffset = xIterationOffset + baseWidth + 36
  if i % 10 == 0
    xIterationOffset = 0
    yIterationOffset = yIterationOffset + baseDepth + 72
  end

end
}

# Define toolbar button
icon = File.join(__dir__, 'icon.png')
cmd.small_icon = icon
cmd.large_icon = icon
cmd.tooltip = "Batch Create CSV"
cmd.status_bar_text = "Creates multiple junction boxes based on values from loaded .csv file"
toolbar = toolbar.add_item cmd
toolbar.show

end