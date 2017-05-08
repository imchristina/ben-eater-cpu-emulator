require "cpu"
suit = require "suit"
updateCPU()
ram.contents[0] = 113
ram.contents[1] = 78
ram.contents[2] = 112
ram.contents[3] = 80
ram.contents[4] = 46
ram.contents[5] = 79
ram.contents[6] = 30
ram.contents[7] = 77
ram.contents[8] = 31
ram.contents[9] = 78
ram.contents[10] = 29
ram.contents[11] = 128
ram.contents[12] = 99
ram.contents[13] = 0
ram.contents[14] = 0
ram.contents[15] = 0
clk.rate = 0

local lastClockChange = 0
local clkEnable = {text = "CLK Enable", checked = false}
local clkRate = {value = 1, min = 0.5, max = 100}
function love.update(dt)
	if clk.rate > 0 then
		lastClockChange = lastClockChange + (dt*clk.rate)*2
		while lastClockChange >= 1 do
			if clk.state then
				clk.state = false
			else
				clk.state = true
			end
			updateCPU()
			lastClockChange = lastClockChange - 1
		end
	end
	suit.Checkbox(clkEnable, 25, 25, 30, 30)
	if clkEnable.checked then
		clk.rate = clkRate.value
	else
		clk.rate = 0
	end
	if suit.Button("CLK", 75,25, 50,30).hit and clk.rate == 0 then
		if clk.state then
			clk.state = false
		else
			clk.state = true
		end
		updateCPU()
	end
	suit.Slider(clkRate, 130,20, 200,20)
    suit.Label(tostring(clkRate.value).."Hz", 130,35, 200,20)
end

function toBits(num)
    -- returns a table of bits, least significant first.
    local t={} -- will contain the bits
    while num>0 do
        rest=math.fmod(num,2)
        t[#t+1]=rest
        num=(num-rest)/2
    end
    return t
end

function drawLEDs(value, bits, x, y, xAdd, yAdd, onCol, offCol)
	x = x + 7.5/2
	y = y + 7.5/2
	if not onCol then
		onCol = {255, 0, 0}
	end
	if not offCol then
		offCol = {50, 0, 0}
	end
	local _digits = string.len(table.concat(toBits(value)))
	if string.len(table.concat(toBits(value))) < bits then
		_digits = bits
	end
	x = x + (xAdd*bits)
	y = y + (yAdd*bits)
	for i = 1, _digits do
		if string.sub(table.concat(toBits(value)), i, i) == "1" then
			love.graphics.setColor(onCol)
		else
			love.graphics.setColor(offCol)
		end
		love.graphics.circle("fill", x, y, 7.5)
		x = x - xAdd
		y = y - yAdd
	end
	love.graphics.setColor(255,255,255)
end

function love.draw()
	love.graphics.setBackgroundColor(0,0,0)
	local _clk = 0
	if clk.state then _clk = 1 end
	drawLEDs(_clk, 1, 350, 25, 0, 0, {0, 0, 255}, {0, 0, 50}) --clock
	--[[_clk = 0
	if not clk.state then _clk = 1 end
	drawLEDs(_clk, 1, 25, love.graphics.getHeight() -25, 0, 0, {0, 0, 255}, {0, 0, 50}) --clock inverted]]
	drawLEDs(bus.value, 8, 375, 25, 25, 0) --Bus
	drawLEDs(pc.value, 4, 600, 25, 25, 0, {0,255,0}, {0,50,0}) --Program counter
	drawLEDs(cont.stage, 3, 200, love.graphics.getHeight() - 100, 25, 0) --control stage binary
	drawLEDs(math.floor(ir.value % 2^8 / 2^4), 4, 100, love.graphics.getHeight() - 200, 25, 0, {0, 0, 255}, {0, 0, 50}) --instruction register, higher four bits
	drawLEDs(math.floor(ir.value % 2^4), 4, 200, love.graphics.getHeight() - 200, 25, 0, {255, 255, 0}, {50, 50, 0}) --lower four bits
	drawLEDs(ram.contents[ram.adr], 8, 100, love.graphics.getHeight()/2, 25, 0) --RAM contents
	drawLEDs(ram.adr, 4, 100, 350, 25, 0, {255, 255, 0}, {50, 50, 0}) --RAM address
	drawLEDs(a.value, 8, love.graphics.getWidth()-250, 250, 25, 0) --Register A
	love.graphics.setColor(255,255,255)
	love.graphics.print("Register A", love.graphics.getWidth()-300, 245)
	local _alu = a.value+b.value
	if alu.sub then _alu = a.value-b.value end
	drawLEDs(math.floor(_alu % 2^8), 8, love.graphics.getWidth()-275, love.graphics.getHeight()/2, 25, 0) --ALU
	love.graphics.setColor(255,255,255)
	love.graphics.print("Sum Register", love.graphics.getWidth()-345,(love.graphics.getHeight()/2)-5)
	drawLEDs(b.value, 8, love.graphics.getWidth()-250, love.graphics.getHeight()-275, 25, 0) --Register A
	love.graphics.setColor(255,255,255)
	love.graphics.print(out.value, love.graphics.getWidth()-250, love.graphics.getHeight()-150) --Out Register
	suit.draw()
end

function love.keypressed(key)
	suit.keypressed(key)
	if key == "space" then
		if clk.state then
			clk.state = false
		else
			clk.state = true
		end
		updateCPU()
	end
end

function love.textinput(t)
    suit.textinput(t)
end
