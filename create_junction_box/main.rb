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
  end
    
  $hole_punch = entities.add_group
  # $pipe_punch = entities.add_group

  
  for i in 0..(holeValues.length - 1) do 
    pipeAngle = holeValues[i][0].to_f
    holeUp = holeValues[i][1].to_f
    holeOffsetX = holeValues[i][2].to_f
    holeOffsetY = holeValues[i][3].to_f
    holeDiameter = holeValues[i][4].to_f 
    pipeInvert = holeValues[i][5].to_f
    pipeDiameter = holeValues[i][6].to_f

    # Calculate the center point coordinates of the pipe
    theta = pipeAngle * Math::PI / 180

    # if holeOffsetX == 0 && holeOffsetY == 0
    ### Top or Bottom wall
    if holeOffsetY == 0 
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
        sign = -1
      elsif pipeAngle > 89 && pipeAngle < 271 #bottom wall
        yEdge = yIterationOffset + depthOffset
        alpha = (pipeAngle - dir) * Math::PI / 180
        sign = 1
      end

      #find center point from edge point
      xCenter = xEdge + (Math.sin(alpha) * (holeDiameter / 2))
      yCenter = yEdge + (Math.cos(alpha) * (holeDiameter / 2))
      zCenter = elevationOffset + baseHeight + holeUp + (holeDiameter / 2)
      extrudeDepth = boxThickness * 3
      pipeExtrudeOffset = extrudeDepth
      pipeExtrudeDepth = pipeExtrudeOffset + 3

      pipeLineOut = boxThickness * 3

      yChange = yEdge - yCenter
      distToWall = yChange / Math.cos(theta - Math::PI)
      distThroughWall = boxThickness / Math.cos(theta - Math::PI)
      distPastWall = 3 / Math.cos(theta - Math::PI)
      pipeLineIn = (distToWall + distThroughWall + distPastWall) * sign
    
    ### Left or Right wall
    elsif holeOffsetX == 0 
      #edge point y value
      if holeOffsetY < 0 # offset from Top wall
        yEdge = yIterationOffset + depthOffset + boxWidth + holeOffsetY
        dir = -90
      elsif holeOffsetY > 0 # offset from Bottom wall
        yEdge = yIterationOffset + depthOffset + holeOffsetY
        dir = 90
      else # 0 offset
        yEdge = yIterationOffset + depthOffset + boxThickness 
        dir = 90
      end

      #edge point x value
      if pipeAngle < 180 # right wall
        xEdge = xIterationOffset + widthOffset + boxWidth
        alpha = (pipeAngle - dir) * Math::PI / 180
        sign = -1
      elsif pipeAngle > 179 # left wall
        xEdge = xIterationOffset + widthOffset
        alpha = (pipeAngle + dir) * Math::PI / 180
        sign = 1
      end

      #find center point from edge point
      xCenter = xEdge + (Math.sin(alpha) * (holeDiameter / 2))
      yCenter = yEdge + (Math.cos(alpha) * (holeDiameter / 2))
      zCenter = elevationOffset + baseHeight + holeUp + (holeDiameter / 2)
      extrudeDepth = boxThickness * 3
      pipeExtrudeOffset = extrudeDepth
      pipeExtrudeDepth = pipeExtrudeOffset + 3
      
      pipeLineOut = boxThickness * 3

      xChange = xEdge - xCenter
      
      distToWall = xChange / Math.cos((Math::PI / 2) - (theta - Math::PI))
      distThroughWall = boxThickness / Math.cos((Math::PI / 2) - (theta - Math::PI))
      distPastWall = 3 / Math.cos((Math::PI / 2) - (theta - Math::PI))
      pipeLineIn = (distToWall + distThroughWall + distPastWall) * sign

    ### corner
    else 
      # edge points
      if holeOffsetX > 0  && holeOffsetY > 0 # bottom left corner
        xEdge1 = xIterationOffset + widthOffset + holeOffsetX
        yEdge1 = yIterationOffset + depthOffset + boxThickness
        xEdge2 = xIterationOffset + widthOffset + boxThickness
        yEdge2 = yIterationOffset + depthOffset + holeOffsetY
      elsif holeOffsetX < 0 && holeOffsetY > 0 # bottom right corner
        xEdge1 = xIterationOffset + widthOffset + boxWidth + holeOffsetX
        yEdge1 = yIterationOffset + depthOffset + boxThickness
        xEdge2 = xIterationOffset + widthOffset + boxWidth - boxThickness
        yEdge2 = yIterationOffset + depthOffset + holeOffsetY
      elsif holeOffsetX < 0 && holeOffsetY < 0 # top right corner
        xEdge1 = xIterationOffset + widthOffset + boxWidth + holeoffsetX
        yEdge1 = yIterationOffset + depthOffset + boxDepth - boxThickness
        xEdge2 = xIterationOffset + widthOffset + boxWidth - boxThickness
        yEdge2 = yIterationOffset + depthOffset + boxWidth + holeOffsetY
      elsif holeOffsetX > 0 && holeOffsetY < 0 # top left corner
        xEdge1 = xIterationOffset + widthOffset + holeOffsetX
        yEdge1 = yIterationOffset + depthOffset + boxDepth - boxThickness
        xEdge2 = xIterationOffset + widthOffset + boxThickness
        yEdge2 = yIterationOffset + depthOffset + boxDepth + holeOffsetY
      end

      #find center point from 2 edge points
      xCenter = (xEdge1 + xEdge2) / 2
      yCenter = (yEdge1 + yEdge2) / 2
      zCenter = elevationOffset + baseHeight + holeUp + (holeDiameter / 2)
      extrudeDepth = boxThickness * -6
      pipeExtrudeOffset = -extrudeDepth
      pipeExtrudeDepth = pipeExtrudeOffset

      pipeLineOut = boxThickness * 6
      pipeLineIn = 3

    end

    # create pipe

    #hole in box
    extrudeCyl(xCenter, yCenter, zCenter, holeDiameter, theta, extrudeDepth, $hole_punch)

    #make pipe
    xCenterPipe1 = xCenter + (Math.sin(theta + Math::PI) * pipeLineIn)
    yCenterPipe1 = yCenter + (Math.cos(theta + Math::PI) * pipeLineIn)

    xCenterPipe2 = xCenter + (Math.sin(theta) * pipeLineOut)
    yCenterPipe2 = yCenter + (Math.cos(theta) * pipeLineOut)

    zCenterPipe = (pipeInvert * 12) + (pipeDiameter / 2)

    $make_pipe = entities.add_group
    # extrudeCyl(xCenterPipe1, yCenterPipe1, zCenterPipe, (pipeDiameter + 2), theta, pipeExtrudeDepth, $pipe)
    # extrudeCyl(xCenterPipe2, yCenterPipe2, zCenterPipe + 0.001, pipeDiameter, theta, pipeExtrudeDepth, $make_pipe)

    # create pipe invert line
    pipeInvertPoint1 = Geom::Point3d.new(xCenterPipe1, yCenterPipe1, (pipeInvert * 12))
    pipeInvertPoint2 = Geom::Point3d.new(xCenterPipe2, yCenterPipe2, (pipeInvert * 12))
    $make_pipe.entities.add_line(pipeInvertPoint1, pipeInvertPoint2)
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

  elevationLine = entities.add_group
  linePoint1 = Geom::Point3d.new(xIterationOffset, yIterationOffset, 0)
  linePoint2 = Geom::Point3d.new(xIterationOffset + 1, yIterationOffset, 0)
  elevationLine.entities.add_line(linePoint1, linePoint2)

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
  
  holeInputs = 7
  numHoles = (table[i].length - 12) / holeInputs
  holeValues = []
  for n in 0..(numHoles-1) do
    unless table[i][12+(n*holeInputs)].to_f == 0 && table[i][13+(n*holeInputs)].to_f == 0 && table[i][14+(n*holeInputs)].to_f == 0 && table[i][15+(n*holeInputs)].to_f == 0 && table[i][16+(n*holeInputs)].to_f == 0 && table[i][17+(n*holeInputs)].to_f == 0 && table[i][18+(n*holeInputs)].to_f == 0
      holeValues = [[table[i][12+(n*holeInputs)].to_f, table[i][13+(n*holeInputs)].to_f, table[i][14+(n*holeInputs)].to_f, table[i][15+(n*holeInputs)].to_f, table[i][16+(n*holeInputs)].to_f, table[i][17+(n*holeInputs)].to_f, table[i][18+(n*holeInputs)].to_f]].unshift(*holeValues)
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