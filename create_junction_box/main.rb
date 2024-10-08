require 'sketchup.rb'
require 'csv'
require 'win32ole'

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
def JunctionBox.main(fileDir, jbName, jbType, topElevation, xIterationOffset, yIterationOffset, 
                      baseWidth, baseDepth, baseHeight, 
                      boxWidth, boxDepth, boxHeight, boxThickness, 
                      lidHoleWidth, lidHoleDepth, lidHeight, lidHoleXOffset, lidHoleYOffset,
                      holeValues)

  elevationOffset = (topElevation * 12) - lidHeight - boxHeight - baseHeight                  
  
  # Make Base
  model = Sketchup.active_model
  #model.start_operation('Create JB Box', true)
  $group = model.active_entities.add_group
  $group.name = jbName.to_s
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
        yInWall = yIterationOffset + depthOffset + boxDepth - boxThickness - 3
        yOutWall = yIterationOffset + depthOffset + boxDepth + 24
      elsif pipeAngle > 89 && pipeAngle < 271 #bottom wall
        yEdge = yIterationOffset + depthOffset
        alpha = (pipeAngle - dir) * Math::PI / 180
        sign = 1
        yInWall = yIterationOffset + depthOffset + boxThickness + 3
        yOutWall = yIterationOffset + depthOffset - 24
      end

      #find center point from edge point
      xCenter = xEdge + (Math.sin(alpha) * (holeDiameter / 2))
      yCenter = yEdge + (Math.cos(alpha) * (holeDiameter / 2))
      zCenter = elevationOffset + baseHeight + holeUp + (holeDiameter / 2)
      extrudeDepth = boxThickness * 3
      pipeExtrudeOffset = extrudeDepth
      pipeExtrudeDepth = pipeExtrudeOffset + 3

      pipeLineOut = boxThickness * 3
      pipeLineIn = boxThickness * 3

      # point of pipe inside box
      m = Math.cos(theta) / Math.sin(theta)
      xInWall = ((yInWall - yCenter) / m) + xCenter

      # point of pipe outside box
      xOutWall = ((yOutWall - yCenter) / m) + xCenter

    
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
        xInWall = xIterationOffset + widthOffset + boxWidth - boxThickness - 3
        xOutWall = xIterationOffset + widthOffset + boxWidth + 24
      elsif pipeAngle > 179 # left wall
        xEdge = xIterationOffset + widthOffset
        alpha = (pipeAngle + dir) * Math::PI / 180
        sign = 1
        xInWall = xIterationOffset + widthOffset + boxThickness + 3
        xOutWall = xIterationOffset + widthOffset - 24
      end

      #find center point from edge point
      xCenter = xEdge + (Math.sin(alpha) * (holeDiameter / 2))
      yCenter = yEdge + (Math.cos(alpha) * (holeDiameter / 2))
      zCenter = elevationOffset + baseHeight + holeUp + (holeDiameter / 2)
      extrudeDepth = boxThickness * 3
      pipeExtrudeOffset = extrudeDepth
      pipeExtrudeDepth = pipeExtrudeOffset + 3
      
      pipeLineOut = boxThickness * 3
      pipeLineIn = boxThickness * 3


      # point of pipe inside box
      m = Math.cos(theta) / Math.sin(theta)
      yInWall = (m * (xInWall - xCenter)) + yCenter

      # point of pipe outside box
      yOutWall = (m * (xOutWall - xCenter)) + yCenter


    ### corner
    else 
      # edge points
      if holeOffsetX > 0  && holeOffsetY > 0 # bottom left corner
        xEdge1 = xIterationOffset + widthOffset + holeOffsetX
        yEdge1 = yIterationOffset + depthOffset + boxThickness
        xEdge2 = xIterationOffset + widthOffset + boxThickness
        yEdge2 = yIterationOffset + depthOffset + holeOffsetY
        yOutWall = yIterationOffset + depthOffset - 24
      elsif holeOffsetX < 0 && holeOffsetY > 0 # bottom right corner
        xEdge1 = xIterationOffset + widthOffset + boxWidth + holeOffsetX
        yEdge1 = yIterationOffset + depthOffset + boxThickness
        xEdge2 = xIterationOffset + widthOffset + boxWidth - boxThickness
        yEdge2 = yIterationOffset + depthOffset + holeOffsetY
        yOutWall = yIterationOffset + depthOffset - 24
      elsif holeOffsetX < 0 && holeOffsetY < 0 # top right corner
        xEdge1 = xIterationOffset + widthOffset + boxWidth + holeoffsetX
        yEdge1 = yIterationOffset + depthOffset + boxDepth - boxThickness
        xEdge2 = xIterationOffset + widthOffset + boxWidth - boxThickness
        yEdge2 = yIterationOffset + depthOffset + boxWidth + holeOffsetY
        yOutWall = yIterationOffset + depthOffset + boxDepth + 24
      elsif holeOffsetX > 0 && holeOffsetY < 0 # top left corner
        xEdge1 = xIterationOffset + widthOffset + holeOffsetX
        yEdge1 = yIterationOffset + depthOffset + boxDepth - boxThickness
        xEdge2 = xIterationOffset + widthOffset + boxThickness
        yEdge2 = yIterationOffset + depthOffset + boxDepth + holeOffsetY
        yOutWall = yIterationOffset + depthOffset + boxDepth + 24
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

      # point of pipe inside box
      xInWall = xCenter
      yInWall = yCenter

      # point of pipe outside box
      m = Math.cos(theta) / Math.sin(theta)
      xOutWall = ((yOutWall - yCenter) / m) + xCenter

    end

    # create pipe

    xCenterPipeIn = xCenter + (Math.sin(theta + Math::PI) * pipeLineIn)
    yCenterPipeIn = yCenter + (Math.cos(theta + Math::PI) * pipeLineIn)

    xCenterPipeOut = xCenter + (Math.sin(theta) * pipeLineOut)
    yCenterPipeOut = yCenter + (Math.cos(theta) * pipeLineOut)

    zCenterPipe = (pipeInvert * 12) + (pipeDiameter / 2)

    pipeDepth = Math.sqrt((xInWall - xOutWall)**2 + (yInWall - yOutWall)**2)

    extrudeCyl(xOutWall, yOutWall, zCenter, holeDiameter, theta, pipeDepth + 3, $hole_punch)

    # extrudeCyl(xCenterPipe1, yCenterPipe1, zCenterPipe, (pipeDiameter + 2), theta, pipeExtrudeDepth, $pipe)
    # extrudeCyl(xCenterPipe2, yCenterPipe2, zCenterPipe + 0.001, pipeDiameter, theta, pipeExtrudeDepth, $make_pipe)

    # create pipe invert line
    $make_pipe = entities.add_group
    pipeInvertPoint1 = Geom::Point3d.new(xInWall, yInWall, (pipeInvert * 12))
    pipeInvertPoint2 = Geom::Point3d.new(xOutWall, yOutWall, (pipeInvert * 12))
    $make_pipe.entities.add_line(pipeInvertPoint1, pipeInvertPoint2)
  end

  $hole_punch.subtract($box)



  # Make Lid
  if lidHoleWidth == 0 && lidHoleDepth == 0 && lidHeight == 0   ### -- TODO: Deal with blank cells -- ###
  else
    #model.commit_operation
    model = Sketchup.active_model
    #model.start_operation('Create JB Lid', true)
 
    widthOffset = (baseWidth-boxWidth) / 2
    depthOffset = (baseDepth-boxDepth) / 2


    $lid = entities.add_group
    if jbType == "Type 18" || jbType == "Type 18 Curb Inlet MOD" || jbType == "Type 18 Curb Inlet"
      curbOffset = UI.inputbox(["How far past the box does the lid go?"])[0].to_f
      
      curbOffsetBottom = -curbOffset
      curbOffsetTop = curbOffset

    elsif jbType == "Type 17 Left Curb Inlet"
      curbOffset = UI.inputbox(["How far past the box does the lid go?"])[0].to_f

      curbOffsetBottom = 0
      curbOffsetTop = curbOffset

    elsif jbType == "Type 17 Right Curb Inlet"
      curbOffset = UI.inputbox(["How far past the box does the lid go?"])[0].to_f

      curbOffsetBottom = -curbOffset
      curbOffsetTop = 0

    else
      curbOffsetBottom = 0
      curbOffsetTop = 0
    end

    # full lid rectangle

    extrudeRect(widthOffset + xIterationOffset, depthOffset + yIterationOffset + curbOffsetBottom,
                widthOffset + boxWidth + xIterationOffset, depthOffset + boxDepth + yIterationOffset + curbOffsetTop,
                baseHeight + boxHeight + elevationOffset, lidHeight, $lid)

    # remove lid hole

    # x coordinate of center point
    if lidHoleXOffset >= 0 # from left side
      xHoleCenter = xIterationOffset + widthOffset + lidHoleXOffset
    elsif lidHoleXOffset < 0 # from right side
      xHoleCenter = xIterationOffset + widthOffset + boxWidth + lidHoleXOffset
    end
    
    # y coordinate of center point
    if lidHoleYOffset >= 0 
      yHoleCenter = yIterationOffset + depthOffset + lidHoleYOffset + curbOffsetBottom
    elsif lidHoleYOffset < 0
      yHoleCenter = yIterationOffset + depthOffset + boxWidth + lidHoleYOffset + curbOffsetTop
    end

    zHoleCenter = baseHeight + boxHeight + elevationOffset + lidHeight + 1

    $lidPunch = entities.add_group

    #circular hole
    if lidHoleWidth != 0 && lidHoleDepth == 0
      center_point = Geom::Point3d.new(xHoleCenter, yHoleCenter, zHoleCenter)
      normal_vector = Geom::Vector3d.new(0,0,-1)
      radius = lidHoleWidth / 2

      hole_circle = $lidPunch.entities.add_circle(center_point, normal_vector, radius)
      face = $lidPunch.entities.add_face(hole_circle)
      face.pushpull(lidHeight + 1)

    #rectangular hole
    else
      extrudeRect(xHoleCenter - (lidHoleWidth / 2), yHoleCenter - (lidHoleDepth / 2),
                  xHoleCenter + (lidHoleWidth / 2), yHoleCenter + (lidHoleDepth / 2),
                  zHoleCenter, -lidHeight - 1, $lidPunch
                  )
    end

    $lidPunch.subtract($lid)


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
file = UI.openpanel('Select File', 'c:\\')
fileFormat = UI.inputbox(["Which format is your file in? \n1: CSV \n2: Excel"])
if fileFormat[0].to_f == 1
  table = CSV.read(file)
  boxNum = table.length
  basename = File.basename(file, ".csv").to_s
elsif fileFormat[0].to_f == 2
  excel = WIN32OLE.new('Excel.Application')
  workbook = excel.Workbooks.Open(file)
  worksheet = workbook.Worksheets(1)
  basename = File.basename(file, ".xlsx").to_s
end

# Create component save directory
pathName = file.to_s
pathName.slice!(File.basename(file).to_s)
fileDir = pathName + basename
unless File.directory?(fileDir)
  Dir.mkdir(fileDir)
end

xIterationOffset = 0
yIterationOffset = 0


if fileFormat[0].to_f == 1
  # Create each box
  for i in 1..(boxNum - 1) do
    # Identify variables
    jbName = table[i][0]
    jbType = table[i][1].to_s
    topElevation = table[i][2].to_f
    baseWidth = table[i][3].to_f
    baseDepth = table[i][4].to_f
    baseHeight = table[i][5].to_f
    
    boxWidth = table[i][6].to_f
    boxDepth = table[i][7].to_f
    boxHeight = table[i][8].to_f
    boxThickness = table[i][9].to_f
    
    lidHoleWidth = table[i][10].to_f
    lidHoleDepth = table[i][11].to_f
    lidHeight = table[i][12].to_f
    lidHoleXOffset = table[i][13].to_f
    lidHoleYOffset = table[i][14].to_f

    holeInputs = 7
    numHoles = (table[i].length - 15) / holeInputs
    holeValues = []
    for n in 0..(numHoles-1) do
      unless table[i][15+(n*holeInputs)].to_f == 0 && table[i][16+(n*holeInputs)].to_f == 0 && table[i][17+(n*holeInputs)].to_f == 0 && table[i][18+(n*holeInputs)].to_f == 0 && table[i][19+(n*holeInputs)].to_f == 0 && table[i][20+(n*holeInputs)].to_f == 0 && table[i][21+(n*holeInputs)].to_f == 0
        holeValues = [[table[i][15+(n*holeInputs)].to_f, table[i][16+(n*holeInputs)].to_f, table[i][17+(n*holeInputs)].to_f, table[i][18+(n*holeInputs)].to_f, table[i][19+(n*holeInputs)].to_f, table[i][20+(n*holeInputs)].to_f, table[i][21+(n*holeInputs)].to_f]].unshift(*holeValues)
      end
    end

    # Make junction box
    main(fileDir, jbName, jbType, topElevation, xIterationOffset, yIterationOffset, 
    baseWidth, baseDepth, baseHeight, 
    boxWidth, boxDepth, boxHeight, boxThickness, 
    lidHoleWidth, lidHoleDepth, lidHeight, lidHoleXOffset, lidHoleYOffset,
    holeValues)

    xIterationOffset = xIterationOffset + baseWidth + 36
    if i % 10 == 0
      xIterationOffset = 0
      yIterationOffset = yIterationOffset + baseDepth + 72
    end
  end

elsif fileFormat[0].to_f == 2
  row = 2
  loop do
    jbName = worksheet.Cells(row, 1).Value.to_s
    jbType = worksheet.Cells(row, 2).Value.to_s
    topElevation = worksheet.Cells(row, 3).Value.to_f
    baseWidth = worksheet.Cells(row, 4).Value.to_f
    baseDepth = worksheet.Cells(row, 5).Value.to_f
    baseHeight = worksheet.Cells(row, 6).Value.to_f
    
    boxWidth = worksheet.Cells(row, 7).Value.to_f
    boxDepth = worksheet.Cells(row, 8).Value.to_f
    boxHeight = worksheet.Cells(row, 9).Value.to_f
    boxThickness = worksheet.Cells(row, 10).Value.to_f
    
    lidHoleWidth = worksheet.Cells(row, 11).Value.to_f
    lidHoleDepth = worksheet.Cells(row, 12).Value.to_f
    lidHeight = worksheet.Cells(row, 13).Value.to_f
    lidXOffset = worksheet.Cells(row, 14).Value.to_f
    lidYOffset = worksheet.Cells(row, 15).Value.to_f

    if topElevation == 0 && baseWidth == 0 && baseDepth == 0 && baseHeight == 0 && boxWidth == 0 && boxDepth == 0 && boxHeight == 0 && boxThickness == 0 && lidHoleWidth == 0 && lidHoleDepth == 0 && lidHeight == 0
      break
    end

    holeInputs = 7
    holeValues = []
    for n in 0..10
      unless worksheet.Cells(row, 16+(n*holeInputs)).Value.to_f == 0 && worksheet.Cells(row, 17+(n*holeInputs)).Value.to_f == 0 && worksheet.Cells(row, 18+(n*holeInputs)).Value.to_f == 0 && worksheet.Cells(row, 19+(n*holeInputs)).Value.to_f == 0 && worksheet.Cells(row, 20+(n*holeInputs)).Value.to_f == 0 && worksheet.Cells(row, 21+(n*holeInputs)).Value.to_f == 0 && worksheet.Cells(row, 22+(n*holeInputs)).Value.to_f == 0
        holeValues = [[worksheet.Cells(row, 16+(n*holeInputs)).Value.to_f, worksheet.Cells(row, 17+(n*holeInputs)).Value.to_f, worksheet.Cells(row, 18+(n*holeInputs)).Value.to_f, worksheet.Cells(row, 19+(n*holeInputs)).Value.to_f, worksheet.Cells(row, 20+(n*holeInputs)).Value.to_f, worksheet.Cells(row, 21+(n*holeInputs)).Value.to_f, worksheet.Cells(row, 22+(n*holeInputs)).Value.to_f]].unshift(*holeValues)
      end
    end

    # Make junction box
    main(fileDir, jbName, jbType, topElevation, xIterationOffset, yIterationOffset, 
    baseWidth, baseDepth, baseHeight, 
    boxWidth, boxDepth, boxHeight, boxThickness, 
    lidHoleWidth, lidHoleDepth, lidHeight, lidHoleXOffset, lidHoleYOffset,
    holeValues)
    
    xIterationOffset = xIterationOffset + baseWidth + 36
    if row % 10 == 0
      xIterationOffset = 0
      yIterationOffset = yIterationOffset + baseDepth + 72
    end

  row = row + 1
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