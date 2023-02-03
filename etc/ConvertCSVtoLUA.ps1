 $points = import-csv -Path "C:\Users\bkant\Zomboid\mods\Exterminator\etc\AllGridPoints.csv"

 $exportLuaPath = "C:\Users\bkant\Zomboid\mods\Exterminator\etc\"
 $exportLuaFile = "AllGridPoints.lua"

 $exportLua = $exportLuaPath + $exportLuaFile

 if (test-path -Path $exportLua) 
 {
 # Delete and Recreate
 Remove-Item -Path $exportLua
 new-item -Path $exportLuaPath -Name $exportLuaFile
 } else {
 # create the file 
 new-item -Path $exportLuaPath -Name $exportLuaFile
 }

 ## start the header for the arrap
 Add-Content -Path $exportLua -Value "ExterminatorGrid = "
 Add-Content -Path $exportLua -Value "{ "

 $gridA = "A0000000000"
 $gridB = "B0000000000"

 foreach ($checkpoint in $points)
 {
    #check if we are up to a new grid A
    $newgridA = "A" + $checkpoint.gridAcenX + "_" +  $checkpoint.gridAcenY 
    if($gridA -ne $newgridA)
    {
        #close the previuos grid A if it isnt the start
        if($gridA -eq "A0000000000")
        {
            Write-Host "A - FirstLine"
        } else {
        Add-Content -Path $exportLua -Value "      }, "
        Add-Content -Path $exportLua -Value "   }, "
        }
        
        #write a new GridA Header
         $gridA = "A" + $checkpoint.gridAcenX + "_" + $checkpoint.gridAcenY 
         Add-Content -Path $exportLua -Value ("   " + $gridA + " = ")
         Add-Content -Path $exportLua -Value "   { "
    } 

    #check if we are up to a new grid A
    $newgridB = "B" + $checkpoint.gridBcenX + "_" + $checkpoint.gridBcenY 
    if($gridB -ne $newgridB)
    {
        #close the previuos grid B if it isnt the start
        if($gridB -eq "B0000000000")
        {
            Write-Host "B - FirstLine"
        } else {
            Add-Content -Path $exportLua -Value "      }, "
        }
        
        #write a new GridB Header
            $gridB = "B" + $checkpoint.gridBcenX + "_" + $checkpoint.gridBcenY 
            Add-Content -Path $exportLua -Value ("      " + $gridB + " = ")
            Add-Content -Path $exportLua -Value "      { "            
    } 

    #add the line
    Add-Content -Path $exportLua -Value ("        '" + $checkpoint.ID + "',")

 }

 ## end the file
 Add-Content -Path $exportLua -Value "         }, "
 Add-Content -Path $exportLua -Value "      }, "
 Add-Content -Path $exportLua -Value "} "

