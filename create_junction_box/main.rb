require 'sketchup.rb'
require 'csv'

#Namespace
module JunctionBox 

def JunctionBox.main(fileDir, jbName, iterationOffset, baseWidth, baseDepth, baseHeight, boxWidth, boxDepth, boxHeight, boxThickness, lidHoleWidth, lidHoleDepth, lidHeight, holeValues)

  # Make Base
  model = Sketchup.active_model
  model.start_operation('Create JB Box', true)

  group = model.active_entities.add_group
  group.name = jbName
  entities = group.entities  
  box = entities.add_group
  if baseWidth != 0 && baseDepth != 0 && baseHeight != 0   ### -- TODO: Deal with blank cells -- ###
    points = [
      Geom::Point3d.new(0 + iterationOffset,0,0),
      Geom::Point3d.new(baseWidth + iterationOffset,0,0),
      Geom::Point3d.new(baseWidth + iterationOffset,baseDepth,0),
      Geom::Point3d.new(0 + iterationOffset,baseDepth,0)
    ]
    face = box.entities.add_face(points)
    face.pushpull(-baseHeight)
  else
    baseWidth = boxWidth
    baseDepth = boxDepth
    baseHeight = 0.1
  end

  # Make Box 
  if boxWidth != 0 && boxDepth != 0 && boxHeight != 0   ### -- TODO: Deal with blank cells -- ###

    widthOffset = (baseWidth-boxWidth) / 2
    depthOffset = (baseDepth-boxDepth) / 2

    points = [
      Geom::Point3d.new(widthOffset + iterationOffset,depthOffset,baseHeight),
      Geom::Point3d.new(widthOffset + boxWidth + iterationOffset,depthOffset,baseHeight),
      Geom::Point3d.new(widthOffset + boxWidth + iterationOffset,depthOffset + boxDepth,baseHeight),
      Geom::Point3d.new(widthOffset + iterationOffset,depthOffset + boxDepth,baseHeight)
    ]
    face = box.entities.add_face(points)
    face.pushpull(boxHeight)

    points = [
      Geom::Point3d.new(widthOffset + boxThickness + iterationOffset,depthOffset + boxThickness,baseHeight + boxHeight),
      Geom::Point3d.new(widthOffset + boxWidth - boxThickness + iterationOffset,depthOffset + boxThickness,baseHeight + boxHeight),
      Geom::Point3d.new(widthOffset + boxWidth - boxThickness + iterationOffset,depthOffset + boxDepth - boxThickness,baseHeight + boxHeight),
      Geom::Point3d.new(widthOffset + boxThickness + iterationOffset,depthOffset + boxDepth - boxThickness,baseHeight + boxHeight)
    ]
    face = box.entities.add_face(points)
    face.pushpull(-boxHeight)
    

    # Add Pipe Holes (first half)
    hole_punch = entities.add_group
    for i in 0..(holeValues.length - 1) do    

      holeAngle = holeValues[i][0].to_f
      holeUp = holeValues[i][1].to_f
      holeOffset = holeValues[i][2].to_f
      holeHeight = holeValues[i][3].to_f    
      
      theta = holeAngle * Math::PI / 180
      
      # 0 deg wall
      if (holeAngle >= 0 && holeAngle <= 45) || (holeAngle >= 315 && holeAngle <= 360) 
        angleOffset = (1.5 * boxThickness) * Math.tan(theta)
        center_point = Geom::Point3d.new(widthOffset + (boxWidth / 2) - angleOffset + holeOffset + iterationOffset,depthOffset - boxThickness, baseHeight + holeUp + (holeHeight / 2))    
      
      # 90 deg wall
      elsif holeAngle > 45 && holeAngle <= 135
        angleOffset = (1.5 * boxThickness) * Math.tan(theta - (Math::PI / 2))
        center_point = Geom::Point3d.new(widthOffset - boxThickness + iterationOffset,depthOffset + (boxDepth / 2) + angleOffset - holeOffset, baseHeight + holeUp + (holeHeight / 2))    

      # 180 deg wall
      elsif holeAngle > 135 && holeAngle <= 225
        angleOffset = (1.5 * boxThickness) * Math.tan(theta)
        center_point = Geom::Point3d.new(widthOffset + (boxWidth / 2) + angleOffset - holeOffset + iterationOffset,depthOffset + boxDepth + boxThickness, baseHeight + holeUp + (holeHeight / 2))  

      # 270 deg wall
      elsif holeAngle > 225 && holeAngle < 315
        angleOffset = (1.5 * boxThickness) * Math.tan(theta - (Math::PI / 2))
        center_point = Geom::Point3d.new(widthOffset + boxWidth + boxThickness + iterationOffset,depthOffset + (boxDepth / 2) - angleOffset + holeOffset, baseHeight + holeUp + (holeHeight / 2))      

      end

      normal_vector = Geom::Vector3d.new(Math.sin(theta),Math.cos(theta),0)
      radius = (holeHeight / 2)

      hole_outer = hole_punch.entities.add_circle(center_point, normal_vector, radius)
      face = hole_punch.entities.add_face(hole_outer)
      face.pushpull(4 * boxThickness)

      
    end
    hole_punch.subtract(box)
    model.commit_operation    
  
  end
    
    

  
  # Make Lid
  if lidHoleWidth != 0 && lidHoleDepth != 0 && lidHeight != 0   ### -- TODO: Deal with blank cells -- ###
    model = Sketchup.active_model
    model.start_operation('Create JB Lid', true)

    #group = model.active_entities.add_group
    #entities = group.entities  
    widthOffset = (baseWidth-boxWidth) / 2
    depthOffset = (baseDepth-boxDepth) / 2
    points = [
      Geom::Point3d.new(widthOffset + iterationOffset,depthOffset,baseHeight + boxHeight),
      Geom::Point3d.new(widthOffset + boxWidth + iterationOffset,depthOffset,baseHeight + boxHeight),
      Geom::Point3d.new(widthOffset + boxWidth + iterationOffset,depthOffset + boxDepth,baseHeight + boxHeight),
      Geom::Point3d.new(widthOffset + iterationOffset,depthOffset + boxDepth,baseHeight + boxHeight)
    ]
    face = entities.add_face(points)
    face.pushpull(lidHeight)
    lidWidthOffset = ((boxWidth - (2 * boxThickness)) - lidHoleWidth) / 2
    lidDepthOffset = ((boxDepth - (2 * boxThickness)) - lidHoleDepth)

    points = [
      Geom::Point3d.new(widthOffset + boxThickness + lidWidthOffset + iterationOffset,depthOffset + boxThickness + lidDepthOffset,baseHeight + boxHeight),
      Geom::Point3d.new(widthOffset + boxWidth - boxThickness - lidWidthOffset + iterationOffset,depthOffset + boxThickness + lidDepthOffset,baseHeight + boxHeight),
      Geom::Point3d.new(widthOffset + boxWidth - boxThickness - lidWidthOffset + iterationOffset,depthOffset + boxDepth - boxThickness,baseHeight + boxHeight),
      Geom::Point3d.new(widthOffset + boxThickness + lidWidthOffset + iterationOffset,depthOffset + boxDepth - boxThickness,baseHeight + boxHeight)
    ]

    face = entities.add_face(points)
    face.pushpull(-lidHeight)
    #comp = model.entities.add_group(group).to_component
    #comp.name = jbName + "_Lid"
    #compPath = File.join(fileDir, jbName + "_Lid" + ".skp")
    #compdef = comp.definition
    #compdef.save_as(compPath)
    model.commit_operation  
  end
  comp = model.entities.add_group(group).to_component
  comp.name = jbName
  compPath = File.join(fileDir, jbName + ".skp")
  compdef = comp.definition
  compdef.save_as(compPath)

end


toolbar = UI::Toolbar.new "Junction Box"
cmd = UI::Command.new("Batch Create CSV") {


file = UI.openpanel('CSV File', 'c:\\')
table = CSV.read(file)
boxNum = table.length
iterationOffset = 0
fileFormat = UI.inputbox(["Which format is your file in? \n1: \n2: \n3:"])

pathName = file.to_s
basename = File.basename(file, ".csv").to_s
pathName.slice!(File.basename(file).to_s)
fileDir = pathName + basename
unless File.directory?(fileDir)
  Dir.mkdir(fileDir)
end

for i in 1..boxNum do

  jbName = table[i][0]
  baseWidth = table[i][1].to_f
  baseDepth = table[i][2].to_f
  baseHeight = table[i][3].to_f
  
  boxWidth = table[i][4].to_f
  boxDepth = table[i][5].to_f
  boxHeight = table[i][6].to_f
  boxThickness = table[i][7].to_f
  
  lidHoleWidth = table[i][8].to_f
  lidHoleDepth = table[i][9].to_f
  lidHeight = table[i][10].to_f
  
  holeAngle1 = table[i][11].to_f
  holeUp1 = table[i][12].to_f
  holeOffset1 = table[i][13].to_f
  holeHeight1 = table[i][14].to_f
  
  numHoles = (table[i].length - 10) / 4
  holeValues = []
  for n in 0..(numHoles-1) do
    unless table[i][11+(n*4)].to_f == 0 && table[i][12+(n*4)].to_f == 0 && table[i][13+(n*4)].to_f == 0 && table[i][14+(n*4)].to_f == 0
      holeValues = [[table[i][11+(n*4)].to_f, table[i][12+(n*4)].to_f, table[i][13+(n*4)].to_f, table[i][14+(n*4)].to_f]].unshift(*holeValues)
    end
  end
  main(fileDir, jbName, iterationOffset, baseWidth, baseDepth, baseHeight, boxWidth, boxDepth, boxHeight, boxThickness, lidHoleWidth, lidHoleDepth, lidHeight, holeValues)
  iterationOffset = iterationOffset + baseWidth + 36

end
}

icon = File.join(__dir__, 'icon.png')
cmd.small_icon = icon
cmd.large_icon = icon
cmd.tooltip = "Batch Create CSV"
cmd.status_bar_text = "Creates multiple junction boxes based on values from loaded .csv file"
toolbar = toolbar.add_item cmd
toolbar.show

end
