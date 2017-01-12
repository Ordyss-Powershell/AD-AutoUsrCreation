#CSV file picker module start
Function Get-FileName($initialDirectory)
{ 
 [System.Reflection.Assembly]::LoadWithPartialName(“System.windows.forms”) |
 Out-Null
 
 $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
 $OpenFileDialog.initialDirectory = $initialDirectory
 $OpenFileDialog.filter = “All files (*.*)| *.*”
 $OpenFileDialog.ShowDialog() | Out-Null
 $OpenFileDialog.filename
}

#Variable that holds CSV file location from file picker
$path = Get-FileName -initialDirectory “c:\"

import-csv $path |foreach {
New-ADUser -server "SVDPDATADC2" -name $_.DisplayName -UserPrincipalName $_.UserPrincipalName -GivenName $_.FirstName -Surname $_.LastName -DisplayName $_.DisplayName -Description $_.Description -Path $_.Path
Set-ADAccountPassword -server "SVDPDATADC2" -Identity $_.SAMAccountName -Reset -NewPassword (ConvertTo-SecureString –String $_.AccountPassword -AsPlainText -Force)
}