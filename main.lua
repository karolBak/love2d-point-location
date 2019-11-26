UI = require "lib.UI"
v2 = require "lib.v2"
require "kirkpatrick"

font_body = love.graphics.newFont("Cantarell-Regular.otf", 15)
font_title = love.graphics.newFont("Cantarell-Regular.otf", 18)
love.graphics.setLineJoin("bevel")

UI.font = font_body

function love.load()
   love.graphics.setBackgroundColor{ 1,1,1 }
   state = "main"

   edges = {}
   polygon = {}
   mouse_position = v2(0,0)
end

function love.update(dt)
end

function love.mousepressed(x, y, button)
   if button == 1 then
      UI.mousepressed { x = x, y = y }
   end
end

function love.mousereleased(x, y, button)
   if button == 1 then
      UI.mousereleased { x = x, y = y }
      if state == "drawing" then

         local to = mouse_position
         first = first or to

         if last then
            edges[last] = edges[last] or {}
            edges[last][to] = region_id
         end

         if last and ((to-last):len() < 15 or (to-first):len() < 15) then
            if #polygon > 2 then
               edges[last] = edges[last] or {}
               edges[last][first] = region_id
               triangulate(edges, polygon, region_id)
               reset = true
            end
         end
         last = to
         table.insert(polygon, to)

         if reset then
            polygon = {}
            first = nil
            last = nil
            reset = false
            generate_id()
         end
      end
   end
end

function love.mousemoved(x, y)
   min_dist = math.huge
   mouse_position = v2(x,y)

   snapped = false
   for point,_ in pairs(edges) do
      local dist = (mouse_position - point):len()
      if dist < 15 then
         snapped = true
         if dist < min_dist then
            min_dist = dist
            mouse_position = point
         end
      end
      inner_label = inner(edges, mouse_position)
   end
   UI.mousemoved { x = x, y = y }
end

function love.keypressed(key)
   if key == "escape" then
      if love.draw == draw_menu then
         love.event.quit()
      else
         love.draw = draw_menu
      end
   end
end


-- Polygon

function process_polygon()
   local to = v2(x,y)
   first = first or to
   if last then
      edges[last] = edges[last] or {}
      edges[last][to] = region_id
   end
   last = to
   table.insert(polygon, to)
   print(to)
end


-- Drawing
local view = {}

function love.draw()
   view[state]()
   for i = 1,region_id do
      if triangles[i] then
         draw_region(i)
      end
   end
   if state == "drawing" and polygon then draw_unfinished(polygon) end
   if snapped then draw_cursor() end
end

function draw_cursor()
   local ps = love.graphics.getPointSize()
   love.graphics.setPointSize(10)
   love.graphics.points({{ mouse_position.x, mouse_position.y, .8,0,0,1 }})
   love.graphics.setPointSize(ps)
end

function draw_unfinished(polygon)
   local r,g,b,a = love.graphics.getColor()
   local ps = love.graphics.getPointSize()
   local lw = love.graphics.getLineWidth()
   local shape = {}

   for _,point in ipairs(polygon) do
      table.insert(shape, point.x)
      table.insert(shape, point.y)
   end

   table.insert(shape, mouse_position.x)
   table.insert(shape, mouse_position.y)

   love.graphics.setLineWidth(2)
   love.graphics.setColor(0,0,0,.5)
   if #shape > 4 then love.graphics.polygon("fill", shape) end
   love.graphics.setColor(0,0,0,1)
   if #shape > 4 then love.graphics.polygon("line", shape) end
   love.graphics.setPointSize(6)
   love.graphics.points(shape)

   love.graphics.setLineWidth(lw)
   love.graphics.setPointSize(ps)
   love.graphics.setColor(r,g,b,a)
end

function view.main()
   UI.draw { x = 10, y = 10,
      UI.button( "Wczytaj siatkę", function() end ),
      UI.button( "Rysuj", function() 
         edges = {}
         polygon = {}
         state = "drawing" 
         generate_id()
      end ),
      UI.button( "Uruchom algorytm", function() end ),
   }
end

function view.drawing()
   UI.draw { x = 10, y = 10,
      UI.label{ "Is vertex inside?  "..tostring(inner_label) },
   }
end
