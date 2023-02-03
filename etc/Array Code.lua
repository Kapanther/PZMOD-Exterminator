Grid =
{
	A100_100 = 
	{
		B1 = 
		{
			'C1',
			'C2',
			'C3',
			'C4',
			'C5',
		},
		B2 = {'C6','C7','C8','C9','C10',},
		B3 = {'C11','C12','C14','C15','C16',},
	},
	A100200 = 
	{
		B1 = {"C1","C2","C3","C4","C5",},
		B2 = {"C6","C7","C8","C9","C10",},
		B3 = {"C11","C12","C14","C15","C16",},
	},
	A100300 = 
	{
		B1 = {'C1','C2','C3','C4','C5',},
		B2 = {'C6','C7','C8','C9','C10',},
		B3 = {'C11','C12','C14','C15','C16',},
	}
}

local positionX = 100
local positionY = 100

local refGridA = "A" .. positionX .. "_" .. positionY;
local refGridB = "B2";
local grid1
local grid2
local grid3
local grid4

if Grid then
	for indexA,valueA in pairs(Grid) do
		local debugprint
		if refGridA == indexA then
			debugprint = "FoundGrid:" .. refGridA;
			for indexB,ValueB in pairs(valueA) do
				if refGridB == indexB then
					print("FoundtheB")
					for indexC,ValueC in next, ValueB do
							print(ValueC)
					end
				end
			end
		else
			debugprint = "NoGridFound:" .. refGridA;
		end
		print(debugprint)
	end
end


