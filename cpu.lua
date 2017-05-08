clk = {rate = 10, state = true} --clock rate in hz
a, b = {load = false, out = false, value = 0}, {load = false, out = false, value = 0} --A and B registers
ir = {value = 0, load = false, out = false} --instruction register
alu = {sub = false, out = false, carry = false} --Arithmitic Logic Unit
ram = {adr = 0, loadAdr = false, load = false, out = false, contents = {}} --RAM and RAM address
for i=0, 15 do table.insert(ram.contents, i, 0) end	--Fill RAM with zeros
pc = {value = 0, out = false, jmp = false, countEnable = false} --Program Counter
out = {value = 0, load = false} --Output Register/Display
bus = {value = 0} --Bus Value
cont = {stage = 0} --Control Logic

function resetControlSignals()
	a, b = {load = false, out = false, value = a.value}, {load = false, out = false, value = b.value} --A and B registers
	ir = {value = ir.value, load = false, out = false} --instruction register
	alu = {sub = false, out = false, carry = alu.carry} --Arithmitic Logic Unit
	ram = {adr = ram.adr, loadAdr = false, load = false, out = false, contents = ram.contents} --RAM and RAM address
	pc = {value = pc.value, out = false, jmp = false, countEnable = false} --Program Counter
	out = {value = out.value, load = false} --Output Register/Display
end

function updateCPU()
	if clk.state then
		if pc.countEnable then --Program counter count enable
			pc.value = pc.value + 1
			if pc.value > 15 then
				pc.value = 0
			end
		end
		if a.out then				--Outputs to bus
			bus.value = a.value
		elseif b.out then
			bus.value = b.value
		elseif ir.out then
			bus.value = math.floor(ir.value % 2^4)
		elseif alu.out then
			if alu.sub then
				bus.value = math.floor((a.value-b.value) % 2^8)
				if a.value-b.value < 0 then alu.carry = true else alu.carry = false end --Assuming there's a 1 bit register that latches the carry bit when the ALU is set to output
			else
				bus.value = math.floor((a.value+b.value) % 2^8)
				if a.value+b.value > 255 then alu.carry = true else alu.carry = false end
			end
		elseif ram.out then
			if ram.contents[ram.adr] ~= nil then
				bus.value = ram.contents[ram.adr]
			else
				bus.value = 0
			end
		elseif pc.out then
			bus.value = pc.value
		end
		if a.load then				--Loads from bus
			a.value = bus.value
		elseif b.load then
			b.value = bus.value
		elseif ir.load then
			ir.value = bus.value
		elseif ram.loadAdr then
			ram.adr = math.floor(bus.value % 2^4)
		elseif ram.load then
			ram.contents[ram.adr] = bus.value
		elseif pc.jmp then
			pc.value = bus.value
		elseif out.load then
			out.value = bus.value
		end
	elseif not clk.state then
		resetControlSignals() --Set all control signals low/disabled
		local _inst = math.floor(ir.value % 2^8 / 2^4) --Get instruction from top four bits of the instruction register)
		if cont.stage == 0 then --Control logic
			pc.out = true
			ram.loadAdr = true
		elseif cont.stage == 1 then
			ram.out = true
			ir.load = true
			pc.countEnable = true
		elseif cont.stage == 2 then	--instruction microcode starts here
			if _inst == 1 or _inst == 2 or _inst == 4 then --LDA, ADD, STA
				ir.out = true
				ram.loadAdr = true
			elseif _inst == 6 then --JMP
				ir.out = true
				pc.jmp = true
			elseif _inst == 7 then --LDI
				ir.out = true
				a.load = true
			elseif _inst == 8 and alu.carry then --Guessing how most instructions are implimented since they have yet to be explained in detail
				ir.out = true
				pc.jmp = true
			elseif _inst == 14 or _inst == 5 then --OUT, under two numbers?
				a.out = true
				out.load = true
			end
		elseif cont.stage == 3 then
			if _inst == 1 then --LDA
				ram.out = true
				a.load = true
			elseif _inst == 2 then --ADD
				ram.out = true
				b.load = true
			elseif _inst == 4 then --STA
				a.out = true
				ram.load = true
			end
		elseif cont.stage == 4 then
			if _inst == 2 then --ADD
				alu.out = true
				a.load = true
			end
		end
		if cont.stage == 5 then
			cont.stage = 0
		else
			cont.stage = cont.stage + 1
		end
		bus.value = 0
	end
end
