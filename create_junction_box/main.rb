require 'sketchup.rb'
require 'csv'
require 'win32ole'

module JunctionBox 

$debug = 0


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
                      firstTierWidth, firstTierDepth, firstTierHeight, firstTierWallThickness, firstTierAlignment,
                      boxWidth, boxDepth, boxHeight, boxThickness, 
                      lidHoleWidth, lidHoleDepth, lidHeight, lidHoleXOffset, lidHoleYOffset,
                      holeValues)

  warning = []
  elevationOffset = (topElevation * 12) - lidHeight - boxHeight - baseHeight - firstTierHeight                  
  
  #### Setup ####
  model = Sketchup.active_model
  if $debug == 0
    model.start_operation('Create JB Box', true)
  end
  $group = model.active_entities.add_group
  $group.name = jbName.to_s
  entities = $group.entities  

  # check for circular bases
  if firstTierWidth != 0 && firstTierDepth == 0
    baseIfCircle = 1
  else
    baseIfCircle = 0
  end

  # check for circular boxes
  if boxWidth != 0 && boxDepth == 0
    boxIfCircle = 1
  else
    boxIfCircle = 0
  end


  #### Make Base ####
  $base = entities.add_group
  if baseWidth == 0 && baseDepth == 0 && baseHeight == 0 
    baseWidth = boxWidth
    baseDepth = boxDepth
  else 
    if baseIfCircle == 1
      center_point = Geom::Point3d.new(xIterationOffset + (baseWidth / 2), yIterationOffset + (baseWidth / 2), elevationOffset)
      normal_vector = Geom::Vector3d.new(0,0,1)
      radius = baseWidth / 2

      hole_base = $base.entities.add_circle(center_point, normal_vector, radius)
      face = $base.entities.add_face(hole_base)
      face.pushpull(baseHeight)

    elsif baseIfCircle == 0
      extrudeRect(xIterationOffset, yIterationOffset, 
                  baseWidth + xIterationOffset, baseDepth + yIterationOffset, 
                  elevationOffset, baseHeight, $base)
    end
  end
  
  #### Make First Tier of Box ####
  if firstTierWidth == 0 && firstTierDepth == 0 && firstTierHeight == 0 && firstTierWallThickness == 0
    ifFirstTier = 0
  else
    ifFirstTier = 1
    $firstTier = entities.add_group
    if baseIfCircle == 1
      # inner circle
      normal_vector = Geom::Vector3d.new(0,0,1)
      radius = (firstTierWidth - (firstTierWallThickness * 2)) / 2
      center_point = Geom::Point3d.new(xIterationOffset + (baseWidth / 2), yIterationOffset + (baseWidth / 2), elevationOffset + baseHeight + firstTierHeight)
      hole_base = $firstTier.entities.add_circle(center_point, normal_vector, radius)
      face_inner = $firstTier.entities.add_face(hole_base)
      face_inner.pushpull(-firstTierHeight + 0.001)

      # outer circle
      center_point = Geom::Point3d.new(xIterationOffset + (baseWidth / 2), yIterationOffset + (baseWidth / 2), elevationOffset + baseHeight + firstTierHeight)
      radius = firstTierWidth / 2
      hole_base = $firstTier.entities.add_circle(center_point, normal_vector, radius)
      face = $firstTier.entities.add_face(hole_base)
      face.pushpull(-firstTierHeight + 0.001)

      face_inner.pushpull(-firstTierHeight + 0.001)

    elsif baseIfCircle == 0
      extrudeRect(xIterationOffset + firstTierWallThickness, yIterationOffset + firstTierWallThickness,
                    xIterationOffset + baseWidth - firstTierWallThickness, yIterationOffset + baseDepth - firstTierWallThickness,
                    elevationOffset + baseHeight, -baseHeight, $firstTier)
    end
    
  end

  #### Make Box ####
  $box = entities.add_group
  if boxWidth == 0 && boxDepth == 0 && boxHeight == 0
  else
    if ifFirstTier == 1
      baseHeight = baseHeight + 0.001
      boxHeight = boxHeight - 0.001

      # dimension from edge of first tier to inside of box based on manufacturing
      if firstTierWidth == 86 && boxWidth == 60
        secondTierOffset = 12 - boxThickness
      elsif firstTierWidth == 100 && boxWidth == 60
        secondTierOffset = 13 - boxThickness
      elsif firstTierWidth == 114 && boxWidth == 60
        secondTierOffset = 14 - boxThickness
      elsif firstTierWidth == 144 && boxWidth == 60
        secondTierOffset = 15 - boxThickness
      
      elsif firstTierWidth == 100 && boxWidth == 48
        secondTierOffset = 13 - boxThickness
      elsif firstTierWidth == 114 && boxWidth == 48
        secondTierOffset = 14 - boxThickness

      elsif firstTierWidth == 86 && boxWidth == 72
        secondTierOffset = 13 - boxThickness
      elsif firstTierWidth == 100 && boxWidth == 72
        secondTierOffset = 14 - boxThickness
      elsif firstTierWidth == 114 && boxWidth == 72
        secondTierOffset = 15 - boxThickness      
      elsif firstTierWidth == 144 && boxWidth == 72
        secondTierOffset = 16 - boxThickness

      else
        secondTierOffset = firstTierWallThickness - boxThickness
      end

      # top
      if firstTierAlignment == "Top" || firstTierAlignment == "top"
        widthOffset = (baseWidth-boxWidth) / 2
        if baseIfCircle == 1
          if boxIfCircle == 1
            depthOffset = baseWidth - boxWidth - (secondTierOffset) - ((baseWidth - firstTierWidth) / 2)
          else
            depthOffset = baseWidth - boxDepth - (secondTierOffset) - ((baseWidth - firstTierWidth) / 2)
          end
        else
          if boxIfCircle == 1
            depthOffset = baseDepth - boxWidth - (secondTierOffset) - ((baseDepth - firstTierDepth) / 2)
          else
            depthOffset = baseDepth - boxDepth - (secondTierOffset) - ((baseDepth - firstTierDepth) / 2)
          end
        end
      # bottom
      elsif firstTierAlignment == "Bottom" || firstTierAlignment == "bottom"
        widthOffset = (baseWidth-boxWidth) / 2
        if baseIfCircle == 1
          depthOffset = (secondTierOffset) + ((baseWidth - firstTierWidth) / 2)
        else
          depthOffset = (secondTierOffset) + ((baseDepth - firstTierDepth) / 2)
        end
      # left
      elsif firstTierAlignment == "Left" || firstTierAlignment == "left"
        if baseIfCircle == 1
          if boxIfCircle == 1
            depthOffset = (baseWidth-boxWidth) / 2
          else
            depthOffset = (baseWidth-boxDepth) / 2
          end
        else
          if boxIfCircle == 1
            depthOffset = (baseDepth-boxWidth) / 2
          else
            depthOffset = (baseDepth-boxDepth) / 2
          end
        end
        widthOffset = (secondTierOffset) + ((baseWidth - firstTierWidth) / 2)
      # right
      elsif firstTierAlignment == "Right" || firstTierAlignment == "right"
        if baseIfCircle == 1
          if boxIfCircle == 1
            depthOffset = (baseWidth-boxWidth) / 2
          else
            depthOffset = (baseWidth-boxDepth) / 2
          end
        else
          if boxIfCircle == 1
            depthOffset = (baseDepth-boxWidth) / 2
          else
            depthOffset = (baseDepth-boxDepth) / 2
          end
        end
        widthOffset = baseWidth - boxWidth - (secondTierOffset) - ((baseWidth - firstTierWidth) / 2)
      # center
      elsif firstTierAlignment == "Center" || firstTierAlignment == "center"
        widthOffset = (baseWidth-boxWidth) / 2
        if baseIfCircle == 1
          if boxIfCircle == 1
            depthOffset = (baseWidth-boxWidth) / 2
          else
            depthOffset = (baseWidth-boxDepth) / 2
          end
        else
          if boxIfCircle == 1
            depthOffset = (baseDepth-boxWidth) / 2
          else
            depthOffset = (baseDepth-boxDepth) / 2
          end
        end
      else
        warning.append("Incorrect first tier alignment value")
        widthOffset = (baseWidth-boxWidth) / 2
        if baseIfCircle == 1
          if boxIfCircle == 1
            depthOffset = (baseWidth-boxWidth) / 2
          else
            depthOffset = (baseWidth-boxDepth) / 2
          end
        else
          if boxIfCircle == 1
            depthOffset = (baseDepth-boxWidth) / 2
          else
            depthOffset = (baseDepth-boxDepth) / 2
          end
        end
      end
    else
      widthOffset = (baseWidth-boxWidth) / 2
      depthOffset = (baseDepth-boxDepth) / 2
    end

    if boxIfCircle == 1
      # box inner circle
      center_point = Geom::Point3d.new(xIterationOffset + widthOffset + (boxWidth / 2), yIterationOffset + depthOffset + (boxWidth / 2), elevationOffset + baseHeight + boxHeight + firstTierHeight)
      radius = (boxWidth - (2 * boxThickness)) / 2

      hole_base = $box.entities.add_circle(center_point, normal_vector, radius)
      face_inner = $box.entities.add_face(hole_base)
      face_inner.pushpull(-boxHeight)
      
      # box outer circle
      
      center_point = Geom::Point3d.new(xIterationOffset + widthOffset + (boxWidth / 2), yIterationOffset + depthOffset + (boxWidth / 2), elevationOffset + baseHeight + boxHeight + firstTierHeight)
      normal_vector = Geom::Vector3d.new(0,0,1)
      radius = boxWidth / 2

      hole_base = $box.entities.add_circle(center_point, normal_vector, radius)
      face = $box.entities.add_face(hole_base)
      face.pushpull(-boxHeight)

      face_inner.pushpull(-boxHeight)

    elsif boxIfCircle == 0      
      # Box outer rectangle
      extrudeRect(widthOffset + xIterationOffset, depthOffset + yIterationOffset,
                  widthOffset + boxWidth + xIterationOffset, depthOffset + boxDepth + yIterationOffset,
                  baseHeight + elevationOffset + firstTierHeight,boxHeight, $box)
      # Remove box inner rectangle
      extrudeRect(widthOffset + boxThickness + xIterationOffset, depthOffset + boxThickness + yIterationOffset,
                  widthOffset + boxWidth - boxThickness + xIterationOffset, depthOffset + boxDepth - boxThickness + yIterationOffset,
                  baseHeight + boxHeight + elevationOffset + firstTierHeight, -boxHeight, $box)  
    end
  end
    
  $hole_punch = entities.add_group
  $hole_punch_base = entities.add_group


  boxWidth_Top = boxWidth
  boxDepth_Top = boxDepth
  boxHeight_Top = boxHeight
  boxThickness_Top = boxThickness
  boxIfCircle_Top = boxIfCircle

  boxWidth_Bottom = firstTierWidth
  boxDepth_Bottom = firstTierDepth
  boxHeight_Bottom = firstTierHeight
  boxThickness_Bottom = firstTierWallThickness
  boxIfCircle_Bottom = baseIfCircle

  widthOffset_Top = widthOffset
  depthOffset_Top = depthOffset

  widthOffset_Bottom = (baseWidth - firstTierWidth) / 2
  depthOffset_Bottom = (baseDepth - firstTierDepth) / 2

  pipeInTop = 0
  pipeInBottom = 0


  #### Make Pipes ####
  for i in 0..(holeValues.length - 1) do 
    pipeInvert = holeValues[i][0].to_f
    pipeDiameter = holeValues[i][1].to_f
    holeDiameter = holeValues[i][2].to_f
    holeUp = holeValues[i][3].to_f
    pipeAngle = holeValues[i][4].to_f 
    holeOffsetX = holeValues[i][5].to_f
    holeOffsetY = holeValues[i][6].to_f

    # Calculate the center point coordinates of the pipe
    theta = pipeAngle * Math::PI / 180

    # if firstTierWallThickness != 0
    #   holeUp = holeUp - baseHeight
    # end

    if holeUp < firstTierHeight
      widthOffset = widthOffset_Bottom
      if baseIfCircle == 1
        depthOffset = widthOffset_Bottom
      else
        depthOffset = depthOffset_Bottom
      end

      boxWidth = boxWidth_Bottom
      boxDepth = boxDepth_Bottom
      boxHeight = boxHeight_Bottom
      boxThickness = boxThickness_Bottom
      boxIfCircle = boxIfCircle_Bottom
    else
      widthOffset = widthOffset_Top
      depthOffset = depthOffset_Top

      boxWidth = boxWidth_Top
      boxDepth = boxDepth_Top
      boxHeight = boxHeight_Top
      boxThickness = boxThickness_Top
      boxIfCircle = boxIfCircle_Top
    end

    if boxIfCircle == 1
      theta = -theta
      xCenter = xIterationOffset + widthOffset + (boxWidth / 2)
      yCenter = yIterationOffset + depthOffset + (boxWidth / 2)
      zCenter = elevationOffset + baseHeight + holeUp + (holeDiameter / 2)

      innerRadius = (boxWidth - (2 * boxThickness)) / 2

      xInWall = xCenter + ((innerRadius - 8) * Math.cos(theta))
      yInWall = yCenter + ((innerRadius - 8) * Math.sin(theta))

      pipeDepth = 24
      xOutWall = xCenter + ((innerRadius + 24) * Math.cos(theta))
      yOutWall = yCenter + ((innerRadius + 24) * Math.sin(theta))

      center_point = Geom::Point3d.new(xInWall, yInWall, zCenter)
      normal_vector = Geom::Vector3d.new(Math.cos(theta), Math.sin(theta), 0)
      radius = holeDiameter / 2

      if holeUp < firstTierHeight
        pipeInBottom = 1
        if $hole_punch_base.valid? == false
          $hole_punch_base = entities.add_group
        end 
        hole_outer = $hole_punch_base.entities.add_circle(center_point, normal_vector, radius)
        face = $hole_punch_base.entities.add_face(hole_outer)
        face.pushpull(24)
      else
        pipeInTop = 1
        if $hole_punch.valid? == false
          $hole_punch = entities.add_group
        end 
        hole_outer = $hole_punch.entities.add_circle(center_point, normal_vector, radius)
        face = $hole_punch.entities.add_face(hole_outer)
        face.pushpull(24)
        $box = $hole_punch.subtract($box)
      end


    elsif boxIfCircle == 0
      ## If hole is in center of wall
      if holeOffsetX == 0 && holeOffsetY == 0
        if (pipeAngle > 45 && pipeAngle < 136) || (pipeAngle > 225 && pipeAngle < 316)
          # left or right wall
          holeOffsetY = (boxDepth / 2) - (holeDiameter / 2)
        elsif (pipeAngle > 135 && pipeAngle < 226) || (pipeAngle > 315 || pipeAngle < 46)
          # top or bottom wall
          holeOffsetX = (boxWidth / 2) - (holeDiameter / 2)
        end 
      end


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
          yEdge = yIterationOffset + depthOffset + boxDepth + holeOffsetY
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
          xEdge1 = xIterationOffset + widthOffset + boxWidth + holeOffsetX
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
      if holeUp < firstTierHeight
        pipeInBottom = 1
        extrudeCyl(xOutWall, yOutWall, zCenter, holeDiameter, theta, pipeDepth + 3, $hole_punch_base)
      else
        pipeInTop = 1
        if firstTierHeight == 0
          extrudeCyl(xOutWall, yOutWall, zCenter, holeDiameter, theta, pipeDepth + 3, $hole_punch)      
        else firstTierHeight != 0
          hole_punch_top = entities.add_group
          center_point = Geom::Point3d.new(xOutWall, yOutWall, zCenter)
          normal_vector = Geom::Vector3d.new(Math.sin(theta), Math.cos(theta), 0)
          radius = (holeDiameter / 2)

          hole_outer = hole_punch_top.entities.add_circle(center_point, normal_vector, radius)
          face = hole_punch_top.entities.add_face(hole_outer)
          face.pushpull(-(pipeDepth + 3))
          $box = hole_punch_top.subtract($box)
        end
      end
    end
    # extrudeCyl(xCenterPipe1, yCenterPipe1, zCenterPipe, (pipeDiameter + 2), theta, pipeExtrudeDepth, $pipe)
    # extrudeCyl(xCenterPipe2, yCenterPipe2, zCenterPipe + 0.001, pipeDiameter, theta, pipeExtrudeDepth, $make_pipe)

    # create pipe invert line
    $make_pipe = entities.add_group
    pipeInvertPoint1 = Geom::Point3d.new(xInWall, yInWall, (pipeInvert * 12))
    pipeInvertPoint2 = Geom::Point3d.new(xOutWall, yOutWall, (pipeInvert * 12))
    $make_pipe.entities.add_line(pipeInvertPoint1, pipeInvertPoint2)

    holeInvert = (zCenter - (holeDiameter / 2))
    if (pipeInvert * 12) < holeInvert
      warning.append("Pipe #{i} invert below hole")
    end

    if (pipeInvert * 12) > (holeInvert + 6)
      warning.append("Pipe #{i} invert too high")
    end
    
  end

  if pipeInTop == 1 && firstTierHeight == 0
    $hole_punch.subtract($box)
  end
  if pipeInBottom == 1
    $hole_punch_base.subtract($firstTier)
  end


  #### Make Lid ####
  if lidHoleWidth == 0 && lidHoleDepth == 0 && lidHeight == 0
  else

    if $debug == 0
      model.commit_operation
    end
    model = Sketchup.active_model
    if $debug == 0
      model.start_operation('Create JB Lid', true)
    end
 
    if firstTierWallThickness != 0 
      boxWidth = boxWidth_Top
      boxDepth = boxDepth_Top
      boxHeight = boxHeight_Top
      boxThickness = boxThickness_Top
      boxIfCircle = boxIfCircle_Top

      widthOffset = widthOffset_Top
      depthOffset = depthOffset_Top
    end



    $lid = entities.add_group


    if boxIfCircle == 1
      # make lid
      circleLid = entities.add_group

      center_point = Geom::Point3d.new(xIterationOffset + widthOffset + (boxWidth / 2), yIterationOffset + depthOffset + (boxWidth / 2), elevationOffset + baseHeight + boxHeight + lidHeight + firstTierHeight)
      normal_vector = Geom::Vector3d.new(0,0,1)
      radius = boxWidth / 2

      hole_base = $lid.entities.add_circle(center_point, normal_vector, radius)
      face = $lid.entities.add_face(hole_base)
      face.pushpull(-lidHeight)
      
      # remove lid hole

      # x coordinate of center point
      if lidHoleXOffset >= 0 # from left side
        xHoleCenter = xIterationOffset + widthOffset + lidHoleXOffset
      elsif lidHoleXOffset < 0 # from right side
        xHoleCenter = xIterationOffset + widthOffset + boxWidth + lidHoleXOffset
      end
      
      # y coordinate of center point
      if lidHoleYOffset >= 0 
        yHoleCenter = yIterationOffset + depthOffset + lidHoleYOffset
      elsif lidHoleYOffset < 0
        yHoleCenter = yIterationOffset + depthOffset + boxWidth + lidHoleYOffset
      end

      zHoleCenter = baseHeight + boxHeight + elevationOffset + lidHeight + firstTierHeight

      $lidPunch = entities.add_group

      #circular hole
      if lidHoleWidth != 0 && lidHoleDepth == 0
        center_point = Geom::Point3d.new(xHoleCenter, yHoleCenter, zHoleCenter)
        normal_vector = Geom::Vector3d.new(0,0,1)
        radius = lidHoleWidth / 2

        hole_circle = $lidPunch.entities.add_circle(center_point, normal_vector, radius)
        face_hole = $lidPunch.entities.add_face(hole_circle)
        face_hole.pushpull(-lidHeight)

      #rectangular hole
      else
        extrudeRect(xHoleCenter - (lidHoleWidth / 2), yHoleCenter - (lidHoleDepth / 2),
                    xHoleCenter + (lidHoleWidth / 2), yHoleCenter + (lidHoleDepth / 2),
                    zHoleCenter + 1, -lidHeight - 1, $lidPunch
                    )
      end

      $lid = $lidPunch.subtract($lid)

    elsif boxIfCircle == 0
      if jbType == "Type 18" || jbType == "Type 18 Curb Inlet MOD" || jbType == "Type 18 Curb Inlet"
        curbOffset = UI.inputbox([jbName + "\nHow far past the box does the lid go?"])[0].to_f
        
        curbOffsetBottom = -curbOffset
        curbOffsetTop = curbOffset

      elsif jbType == "Type 17 Left Curb Inlet"
        curbOffset = UI.inputbox([jbName + "\nHow far past the box does the lid go?"])[0].to_f

        curbOffsetBottom = 0
        curbOffsetTop = curbOffset

      elsif jbType == "Type 17 Right Curb Inlet"
        curbOffset = UI.inputbox([jbName + "\nHow far past the box does the lid go?"])[0].to_f

        curbOffsetBottom = -curbOffset
        curbOffsetTop = 0

      else
        curbOffsetBottom = 0
        curbOffsetTop = 0
      end

      # full lid rectangle

      extrudeRect(widthOffset + xIterationOffset, depthOffset + yIterationOffset + curbOffsetBottom,
                  widthOffset + boxWidth + xIterationOffset, depthOffset + boxDepth + yIterationOffset + curbOffsetTop,
                  baseHeight + boxHeight + elevationOffset + firstTierHeight, lidHeight, $lid)

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
        yHoleCenter = yIterationOffset + depthOffset + boxDepth + lidHoleYOffset + curbOffsetTop
      end

      zHoleCenter = baseHeight + boxHeight + elevationOffset + lidHeight + firstTierHeight + 1

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
  if $debug == 0
    model.commit_operation  
  end

  return warning
end

#### Setup ####
toolbar = UI::Toolbar.new "Junction Box"
cmd = UI::Command.new("Batch Create CSV") {
# Select and read file
file = UI.openpanel('Select File', 'c:\\')
# fileFormat = UI.inputbox(["Which format is your file in? \n1: CSV \n2: Excel"])
fileFormat = [2]
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


#### CSV Loop ####
if fileFormat[0].to_f == 1
  for i in 1..(boxNum - 1) do
    # Identify variables
    jbName = table[i][0]
    jbType = table[i][1].to_s
    topElevation = table[i][2].to_f
    baseWidth = table[i][3].to_f
    baseDepth = table[i][4].to_f
    baseHeight = table[i][5].to_f
    firstTierWidth = table[i][6].to_f
    firstTierDepth = table[i][7].to_f
    firstTierHeight = table[i][8].to_f
    firstTierWallThickness = table[i][9].to_f
    
    boxWidth = table[i][10].to_f
    boxDepth = table[i][11].to_f
    boxHeight = table[i][12].to_f
    boxThickness = table[i][13].to_f
    
    lidHoleWidth = table[i][14].to_f
    lidHoleDepth = table[i][15].to_f
    lidHeight = table[i][16].to_f
    lidHoleXOffset = table[i][17].to_f
    lidHoleYOffset = table[i][18].to_f

    holeInputs = 7
    numHoles = (table[i].length - 19) / holeInputs
    holeValues = []
    for n in 0..(numHoles-1) do
      unless table[i][19+(n*holeInputs)].to_f == 0 && table[i][20+(n*holeInputs)].to_f == 0 && table[i][21+(n*holeInputs)].to_f == 0 && table[i][22+(n*holeInputs)].to_f == 0 && table[i][23+(n*holeInputs)].to_f == 0 && table[i][24+(n*holeInputs)].to_f == 0 && table[i][25+(n*holeInputs)].to_f == 0 && table[i][26+(n*holeInputs)].to_f == 0
        holeValues = [[table[i][19+(n*holeInputs)].to_f, table[i][20+(n*holeInputs)].to_f, table[i][21+(n*holeInputs)].to_f, table[i][22+(n*holeInputs)].to_f, table[i][23+(n*holeInputs)].to_f, table[i][24+(n*holeInputs)].to_f, table[i][25+(n*holeInputs)].to_f, table[i][26+(n*holeInputs)].to_f]].unshift(*holeValues)
      end
    end

    # Make junction box
    warnings = main(fileDir, jbName, jbType, topElevation, xIterationOffset, yIterationOffset, 
    baseWidth, baseDepth, baseHeight, 
    firstTierWidth, firstTierDepth, firstTierHeight, firstTierWallThickness,
    boxWidth, boxDepth, boxHeight, boxThickness, 
    lidHoleWidth, lidHoleDepth, lidHeight, lidHoleXOffset, lidHoleYOffset,
    holeValues)

    xIterationOffset = xIterationOffset + baseWidth + 36
    if i % 10 == 0
      xIterationOffset = 0
      yIterationOffset = yIterationOffset + baseDepth + 72
    end
  end

#### excel loop ####
elsif fileFormat[0].to_f == 2
  row = 2
  loop do
    jbName = worksheet.Cells(row, 1).Value.to_s
    jbType = worksheet.Cells(row, 2).Value.to_s
    topElevation = worksheet.Cells(row, 3).Value.to_f
    baseWidth = worksheet.Cells(row, 4).Value.to_f
    baseDepth = worksheet.Cells(row, 5).Value.to_f
    baseHeight = worksheet.Cells(row, 6).Value.to_f
    firstTierWidth = worksheet.Cells(row, 7).Value.to_f
    firstTierDepth = worksheet.Cells(row, 8).Value.to_f
    firstTierHeight = worksheet.Cells(row, 9).Value.to_f
    firstTierWallThickness = worksheet.Cells(row, 10).Value.to_f
    firstTierAlignment = worksheet.Cells(row, 11).Value.to_s
    
    boxWidth = worksheet.Cells(row, 12).Value.to_f
    boxDepth = worksheet.Cells(row, 13).Value.to_f
    boxHeight = worksheet.Cells(row, 14).Value.to_f
    boxThickness = worksheet.Cells(row, 15).Value.to_f
    
    lidHoleWidth = worksheet.Cells(row, 16).Value.to_f
    lidHoleDepth = worksheet.Cells(row, 17).Value.to_f
    lidHeight = worksheet.Cells(row, 18).Value.to_f
    lidHoleXOffset = worksheet.Cells(row, 19).Value.to_f
    lidHoleYOffset = worksheet.Cells(row, 20).Value.to_f

    if topElevation == 0 && baseWidth == 0 && baseDepth == 0 && baseHeight == 0 && boxWidth == 0 && boxDepth == 0 && boxHeight == 0 && boxThickness == 0 && lidHoleWidth == 0 && lidHoleDepth == 0 && lidHeight == 0
      break
    end

    holeInputs = 7
    holeValues = []
    for n in 0..10
      unless worksheet.Cells(row, 21+(n*holeInputs)).Value.to_f == 0 && worksheet.Cells(row, 22+(n*holeInputs)).Value.to_f == 0 && worksheet.Cells(row, 23+(n*holeInputs)).Value.to_f == 0 && worksheet.Cells(row, 24+(n*holeInputs)).Value.to_f == 0 && worksheet.Cells(row, 25+(n*holeInputs)).Value.to_f == 0 && worksheet.Cells(row, 26+(n*holeInputs)).Value.to_f == 0 && worksheet.Cells(row, 27+(n*holeInputs)).Value.to_f == 0
        holeValues = [[worksheet.Cells(row, 21+(n*holeInputs)).Value.to_f, worksheet.Cells(row, 22+(n*holeInputs)).Value.to_f, worksheet.Cells(row, 23+(n*holeInputs)).Value.to_f, worksheet.Cells(row, 24+(n*holeInputs)).Value.to_f, worksheet.Cells(row, 25+(n*holeInputs)).Value.to_f, worksheet.Cells(row, 26+(n*holeInputs)).Value.to_f, worksheet.Cells(row, 27+(n*holeInputs)).Value.to_f]].unshift(*holeValues)
      end
    end

    # Make junction box
    warnings = main(fileDir, jbName, jbType, topElevation, xIterationOffset, yIterationOffset, 
                    baseWidth, baseDepth, baseHeight, 
                    firstTierWidth, firstTierDepth, firstTierHeight, firstTierWallThickness, firstTierAlignment,
                    boxWidth, boxDepth, boxHeight, boxThickness, 
                    lidHoleWidth, lidHoleDepth, lidHeight, lidHoleXOffset, lidHoleYOffset,
                    holeValues)
    
    if warnings.length > 0
      for j in 0..warnings.length
        worksheet.Cells(row, 55+j).Value = warnings[j]
      end
      worksheet.Cells(row, 1).Interior.Color = 6

      if File.file?(fileDir + "/" + basename + "_warnings" + ".txt")
        File.write((fileDir + "/" + basename + "_warnings" + ".txt"), (jbName + " " + warnings.to_s + "\n"), mode: 'a+')
      else
        File.write((fileDir + "/" + basename + "_warnings" + ".txt"), (jbName + " " + warnings.to_s + "\n"))
      end

    end

    xIterationOffset = xIterationOffset + baseWidth + 120
    
    if defined?(rowMaxBaseDepth)
      if baseDepth > rowMaxBaseDepth
        rowMaxBaseDepth = baseDepth
      end
    else
      rowMaxBaseDepth = baseDepth
    end

    if row % 10 == 1
      xIterationOffset = 0
      yIterationOffset = yIterationOffset + rowMaxBaseDepth + 72
      if baseDepth == 0
        yIterationOffset = yIterationOffset + baseWidth
      end
    end

  row = row + 1
  end
end 
}

# Define toolbar button
icon = File.join(__dir__, 'icon.png')
cmd.small_icon = icon
cmd.large_icon = icon
cmd.tooltip = "Batch Create Junction Boxes"
cmd.status_bar_text = "Creates multiple junction boxes based on values from loaded from a file"
toolbar = toolbar.add_item cmd
toolbar.show

end