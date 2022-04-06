pico-8 cartridge // http://www.pico-8.com
version 35
__lua__
local player
local map_objects
local game_state
local logo_sprCount
local logo_pix

function _init()
	map_objects={}
	player=make_knight(60,60)
	plat3=make_platform(68,100)
	plat2=make_platform(60,100)
	plat1=make_platform(52,100)
	add(map_objects,plat3)
	add(map_objects,plat2)
	add(map_objects,plat1)
	
	-- game_state at 0001 is displaying the logo --
	-- game_state at 0010 is the start menu --
	-- game_state at 0100 is running the game itself --
	game_state=0b0001
	
	logo_sprCount=0
	logo_pix={}
end

function _update()
	-- Called 30 times a second --
    local obj
	
	if game_state&0b0001==1 then
		-- run the logo --
		if logo_sprCount%5==0 then
			add( logo_pix, make_pix(60,60,(flr(rnd(6))-3),(flr(rnd(6))-3),11,10) )
		end
		
		for obj in all(logo_pix) do
			obj:update()
			
			if obj.life<=0 then
				del(logo_pix,obj)
			end
		end
		
		if btn(4) then
			game_state=0b0100
		end
		
	else	
		for obj in all(map_objects) do
			obj:update()
		end
		player:update()
	end
	
end

function _draw()
	-- Called 30 times a second, this function writes from the draw buffer --
    cls()
    local obj
	
	if game_state&0b0001==1 then
		-- run the logo --
		
		for obj in all(logo_pix) do
			obj:draw()
		end
		
		spr(010, 40, 32, 6, 7)
		if logo_sprCount>10 and logo_sprCount<20 then
			--
			rectfill(65, 42, 65, 42, 7)
		elseif logo_sprCount>20 and logo_sprCount<30 then
			--
			line(64, 42, 65, 41, 7)
		elseif logo_sprCount>30 then
			--
			rectfill(64, 41, 64, 41, 7)
		else
			--
		end
		logo_sprCount+=1
	else	
		for obj in all(map_objects) do
			obj:draw()
		end
		player:draw()
	end
	
end

function make_knight(x,y)
    return make_game_object(001,"knight",x,y,16,16,{
		jumping=false,
		update=function(self)		
			--player movement --
			if (btnp(⬆️) and self.jumping==false) then
				self.y_v=-5
				self.jumping=true
			end
			if btnp(⬇️) then
				--self.y_v+=1--
			end
			if btn(⬅️) then
				self.x_v=-2
			elseif btn(➡️) then
				self.x_v=2
			else
				self.x_v=0
			end	
		
			-- The following is collision code --
			self.x=mid(0,(self.x+self.x_v),120)
			self.y=mid(0,(self.y+self.y_v),96)
			
			for obj in all(map_objects) do
				local hit_dir=self:check_for_collision(obj)
				if hit_dir=="top" and fget(obj.sprite,0) then
					self.y=obj.y+obj.height
				elseif hit_dir=="bottom" and fget(obj.sprite,0) then	
					self.y=obj.y-self.height
					self.jumping=false
				elseif hit_dir=="left" and fget(obj.sprite,0) then	
					self.x=obj.x+obj.width
				elseif hit_dir=="right" and fget(obj.sprite,0) then	
					self.x=obj.x-self.width
				end
			end
			
			-- The force of gravity is 30 px per second, 1 px per update() call --
			-- Unless there is a hit for adjacency in the down direction --
			if (self.y_v<=0) then
				self.y_v+=1
			end
			
		end,
		draw=function(self)
			palt(0,false)
			palt(9,true)
			spr(self.sprite,self.x,self.y,2,2)
			palt(0,true)
			palt(9,false)
		end
	})
end

function make_platform(x,y)
    return make_game_object(064,"block",x,y,8,8,{})
end

function make_pix(x,y,v_x,v_y,colour,life)
	local obj={
		x=x,
		y=y,
		v_x=v_x,
		v_y=v_y,
		colour=colour,
		life=life,
		update=function(self)
			x+=v_x
			y+=v_y
			life-=1
		end,
		draw=function(self)
			line(x, y, x, y, colour)
		end
	}
	return obj
end
	
function make_game_object(sprite,name,x,y,width,height,props)
	local obj={
		-- The top left sprite --
		sprite=sprite,
		-- Game object name --
		name=name,
		-- The top left (x,y)
		x=x,
		y=y,
		-- These are velocity values --
		x_v=0,
		y_v=0,
		-- The full width and height of the complete sprite i.e. 16x16 or 8x8 etc.
		width=width,
		height=height,
		update=function(self)
			-- flag 0 sprites are stationary --
			if(fget(self.sprite,0)==false) then
				-- The force of gravity is 30 px per second, 1 px per update() call --
				if(self.y_v<=0) then
					self.y_v+=1
				end
			end
			
		end,
		draw=function(self)
			spr(self.sprite,self.x,self.y,1,1)
		end,
		check_for_hit=function(self,obj)
			-- Helper function for check_for_collision()
			return obj_overlap(self,obj) 
		end,
		check_for_collision=function(self,obj)
			-- Check to see if this obj has collided with something --
			local top_hitbox={
			    x=self.x+2,
				y=self.y,
				width=self.width-4,
				height=self.height/2
			}
			local bottom_hitbox={
			    x=self.x+2,
				y=self.y+self.height/2,
				width=self.width-4,
				height=self.height/2
			}
			local left_hitbox={
			    x=self.x,
				y=self.y+2,
				width=self.width/2,
				height=self.height-4
			}
			local right_hitbox={
			    x=self.x+self.width/2,
				y=self.y+2,
				width=self.width/2,
				height=self.height-4
			}
			if obj_overlap(top_hitbox, obj) then
				return "top"
			end
			if obj_overlap(bottom_hitbox, obj) then
				return "bottom"
			end
			if obj_overlap(left_hitbox, obj) then
				return "left"
			end
			if obj_overlap(right_hitbox, obj) then
				return "right"
			end
		end,
		check_for_adjacency=function(self,obj,direction)
			local top_hitbox={
			    x=self.x+2,
				y=self.y-2,
				width=self.width-4,
				height=self.height/2
			}
			local bottom_hitbox={
			    x=self.x+2,
				y=self.y+self.height/2,
				width=self.width-4,
				height=(self.height/2)+2
			}
			local left_hitbox={
			    x=(player.x-2),
				y=(player.y+2),
				width=6,
				height=4
			}
			local right_hitbox={
			    x=(player.x+4),
				y=(player.y+2),
				width=6,
				height=4
			}
			
			if direction=="up" and obj_overlap(top_hitbox, obj) then
				return true
			end
			if direction=="down" and obj_overlap(bottom_hitbox, obj) then
				return true
			end
			if direction=="left" and obj_overlap(left_hitbox, obj) then
				return true
			end
			if direction=="right" and obj_overlap(right_hitbox, obj) then
				return true
			end
		end
	}
	local key,value
	for key,value in pairs(props) do
		obj[key]=value
	end
	return obj
end

function line_overlap(min1,max1,min2,max2)
    return max1>min2 and max2>min1
end

function obj_overlap(obj1, obj2)
    return line_overlap(obj1.x,(obj1.x+obj1.width),obj2.x,(obj2.x+obj2.width)) and line_overlap(obj1.y,(obj1.y+obj1.height),obj2.y,(obj2.y+obj2.height))
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000d66d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000d66d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000d66880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000d66880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000d66d50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000d66d50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000ddd66ddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000dd66666666dd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000d6666666666d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000bb33b3bb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000ccccc000cc000cc0bccccc0b000ccc000ccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000cc111cc00cc000cc00bc11cc00cc11cc00cc11cc000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000cc0011100cc000cc0bcc3bccb0cc001100cc00cc000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000cc0000000cc000bc00cc3bccb0bc000000cc00cc000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000001cccc0000cc000cb00bc3ccbb0cbcc0000cc0cc1000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000111cc000cc000ccbbcccc1bb0cc110000ccc1cc000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000001cc00cc000cc0bcc13bbb0cc000000cc11cc000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000cc00cc000cc0bcc333b00cb000000cc00cc000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000cc000cc001ccccc10bcb333b00cc00cc00cc00cc000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000001ccccc10001ccc1000cc3b3bb01cccc100cc00cc000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000001111100000111000b113b3b0001111000110011000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000b3bb3b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000bbbb333b0b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000bb33b300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000ccccc0000cccc00cccccccc00ccccc0000ccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000cc11cc00cc11cc0111cc111b0cc11cc00cc111cc000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000cc00cc00cc00110000ccb33b0cc00cc00cc000cc000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000cc00cc00cc0000000bbc3b300cc00cc00cc000cc000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000cc0cc100cccc000000cc333bbcc0cc100cc000cc000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000ccc1cc00cc11000000cb3b3b0ccc1cc00cc000cc000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000cc11cc00cc00000000ccbb3bbcc11cc00cc000cc000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000cc00cc00cc000000b0bcb33b0cc00cc00cc000cc000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000cc00cc00cc00cc0000cc3b300cc00cc00cc000cc000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000cc00cc001cccc10000cc3b300cc00cc001ccccc1000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000011001100011110000b11b3300110011000111110000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000bb33b3bbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000b0b3bb3bb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000b333bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000bb3b33b00000cccc0000ccccc0000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000ccccc0000cccc000ccb33bbbcc00cc11cc00cc111cc000000000000000000000000000000000000000000000000000000000000000000000000000
000000000cc111cc00cc11cc00ccccb3cccc00cc001100cc00111000000000000000000000000000000000000000000000000000000000000000000000000000
000000000cc0001100cc00cc00bccccccccc00cc000000cc00000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000cc0000000cc0ccc00cc1cccc1cc01cccc00001cccc00000000000000000000000000000000000000000000000000000000000000000000000000000
000000000cc00ccc00ccc1cc00cc01cc1bcc00cc1100000111cc0000000000000000000000000000000000000000000000000000000000000000000000000000
000000000cc000cc00cc10cc00bc00cc00ccb0cc00000000001cc000000000000000000000000000000000000000000000000000000000000000000000000000
000000000cc000cc00cc00cc00cc00cc00cc00cc00000000000cc000000000000000000000000000000000000000000000000000000000000000000000000000
000000000cc000cc00cc00cc00cc00cc00cc00cc00cc00cc000cc000000000000000000000000000000000000000000000000000000000000000000000000000
0000000001cccccc00cc00cc00cc00cc00cc011cccc1001ccccc1000000000000000000000000000000000000000000000000000000000000000000000000000
00000000001111110011001100110011001100011110000111110000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000700000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000700000000000000700000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
