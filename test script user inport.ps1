<#
  Scriptnaam:  MonitorFreeMemory.ps1
  Functie   :  Dit script monitort het vrije geheugen van de machine waarop het script uitgevoerd wordt.
               De resultaten worden weggeschreven naar een resultatenfile als uit te voeren SQL query.
  Auteur    :  Olaf Ritman
  Versie    :  1.0
  Datum     :  12 oktober 2022

  Verwachte argumenten: aantal seconden (numeriek) en naam van de output file (tekst)
#>
clear
$seconds = 5
$ResultFile = 'Results.txt'
$MachineName = hostname

If ($args[0] -Is [int]) {$seconds = $args[0]}
If ($args[1] -Is [string]) {$ResultFile = $args[1]}

If (Test-Path -LiteralPath $ResultFile) {
  Write-Host -ForegroundColor Red "WARNING: " -NoNewline
  Write-Host "$ResultFile already exists. What do you want to do?"
  Write-Host "[1] Add the results to this file"
  Write-Host "[2] Delete it and start with an empty one"
  Write-Host "[9] Quit"
  $answer = Read-Host -Prompt "Please make your choice"

  While (($answer -ne "1") -And ($answer -ne "2") -And ($answer -ne "9")) {
    $answer = Read-Host -Prompt "Please make your choice"
  }
  If ($answer -Eq '2') {
    Set-Content -path $ResultFile -value "DELETE FROM MemoryUsage WHERE ID > 0;"
    Add-Content -path $ResultFile -value "INSERT INTO MemoryUsage (Hostname,FreeMemory,Date) VALUES"
  }
  If ($answer -Eq '9') {
    Exit
  }
}
Else {
  Set-Content -path $ResultFile -value "DELETE FROM MemoryUsage WHERE ID > 0;"
  Add-Content -path $ResultFile -value "INSERT INTO MemoryUsage (Hostname,FreeMemory,Date) VALUES"
}

$aantalSeconden = New-timespan -seconds $seconds
$startAt = Get-Date
$stopAt = (Get-Date) + $aantalSeconden

clear
$LineOut = "Checking free virtual memory on $MachineName for $seconds seconds"
Write-Host $LineOut
$LengthLineOut = $LineOut.Length
For($i=1;$i -le $LengthLineOut;$i++){
  Write-Host -NoNewline "="
}
Write-Host "`r"

while ((Get-Date) -Lt $stopAt) {
  $FreeMemory = Get-CIMInstance Win32_OperatingSystem | Select FreePhysicalMemory
  ForEach ($entry in $FreeMemory){
    $TimeStamp = Get-Date -Format "yyyyMMddHHmmss"
    $MemValue = $entry.FreePhysicalMemory
    $NewLine = "('$MachineName',$MemValue,$TimeStamp),"
    Add-Content -Path $ResultFile -Value $NewLine
    $TimeStamp = Get-Date
    Write-Host "Free memory at ${TimeStamp}:" $entry.FreePhysicalMemory
  }
  Write-Host -NoNewline "> Next check in 3`r";
  Wait-Event -TimeOut 1
  Write-Host -NoNewline "> Next check in 2`r";
  Wait-Event -TimeOut 1
  Write-Host -NoNewline "> Next check in 1`r";
  Wait-Event -TimeOut 1
}

clear
Write-Host -NoNewline "Monitoring process is done. Results can be found in "
Write-Host -ForegroundColor Red $pwd\$ResultFile

$answer = Read-Host -Prompt "`nDo you want to open it (y/n)?";
While (($answer -ne "y") -And ($answer -ne "n")) {
  $answer = Read-Host -Prompt "Please make your choice (y/n)";
}
If ($answer -Eq 'y') {Invoke-Item $ResultFile}
Else {Write-Host "Dan niet joh..."}

Write-Host "================================`nScript finished at", (Get-Date), "`n" ;