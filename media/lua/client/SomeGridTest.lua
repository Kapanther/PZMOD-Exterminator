RawGrid = 
	{ 
	B2 = "Cleared",
	B1 = "Cleared",
	C10_1 = "Cleared",
	C15_3 = "Cleared",
	C20_3 = "Infested",
	C15_2 = "Discovered",
	C10_3 = "Cleared",
	B4 = "Cleared",
	B3 = "Infested",
	}
	
SomeOtherGrid = 
	{ 
	B5 = "Cleared",
	B6 = "Cleared",
	C10_1 = "Cleared",
	C15_3  = "Cleared",
	C20_3 = "Cleared",
	C21_3 = "Cleared",
	C20_4 = "Cleared",
	C20_8 = "Cleared",
	C15_2 = "Discovered",
	C10_3 = "Cleared",
	B4 = "Cleared",
	B3 = "Discovered",
	}

bGrid = {}

function pairsByKeys (t, f)
      local a = {}
      for n in pairs(t) do table.insert(a, n) end
      table.sort(a, f)
      local i = 0      -- iterator variable
      local iter = function ()   -- iterator function
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
      end
      return iter
end

function difference(Ga, Gb)
    local pairsToUpdate = {}
	local pairsCount = 1	
    for iA,vA in pairs(Ga) do
		local gridA = vA[1]
		local markerFound = false
		local countB = 1
		for iB,vB in pairs(Gb) do
			local gridB = vB[1]
			
			if gridA == gridB then
				markerFound = true
				local clearedA = vA[2]
				local clearedB = vB[2]
				--remove table entries as they are both found
				table.remove(Gb,countB)
				if clearedA == clearedB then
				--Do nothing there the same
				elseif clearedA == "Cleared" or clearedB == "Cleared" then
					--they dont match but one is cleared
					pairsToUpdate[pairsCount] = {gridA,"Cleared"}
					pairsCount = pairsCount + 1
					
					--TODO remove the Bgrid line for performance
					elseif clearedA == "Infested" or clearedB == "Infested" then
					pairsToUpdate[pairsCount] = {gridA,"Infested"}
					pairsCount = pairsCount + 1
					--TODO remove the Bgrid line for performance
					else
					pairsToUpdate[pairsCount] = {gridA,"Discovered"}
					pairsCount = pairsCount + 1
					--TODO remove the Bgrid line for performance
				end				
			end
			countB = countB + 1
		end
		if markerFound == false then
		--add markers it wasnt found
		pairsToUpdate[pairsCount] = {gridA,vA[2]}
		pairsCount = pairsCount + 1
		end
	end
	bGrid = Gb   
    return pairsToUpdate
end

function sortGrid (gridToSort)
	local sorted = {}
	local count = 1
	for name, line in pairsByKeys(gridToSort) do
		  sorted[count] = {name,line}
		  count = count + 1
	end
	return sorted
end

--SortedGrid = sortGrid(rawGrid)
--SortedOther = sortGrid(SomeOtherGrid)



sortedGrid1 = sortGrid(RawGrid)
sortedGrid2 = sortGrid(SomeOtherGrid)
diffgrid = difference(sortedGrid1,sortedGrid2)

for index,value in pairs(diffgrid) do
	print (index .. ',' .. value[1] .. ',' .. value[2])
end

for index,value in pairs(bGrid) do
	print ('B' .. index .. ',' .. value[1] .. ',' .. value[2])
end




