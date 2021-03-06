﻿#Credentials to login servers
$O365CREDS = Get-Credential -Message "O365 Crednetials"
$ONPREMCREDS = Get-Credential -Message "On Premise Credentials"

#Connect to O365
Connect-MsolService -Credential $O365CREDS

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
 
#CSV file picker module end

#Import Exchange Module
$SESSION = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Credential $O365CREDS -Authentication Basic -AllowRedirection

#Variable that holds CSV file location from file picker
$path = Get-FileName -initialDirectory “c:\”
 
#Window with list of available 365 licenses and their names
Get-MsolAccountSku | out-gridview
 
#Input window where you provide the license package’s name
$server = read-host ‘Provide licensename (AccountSkuId)’
 
#CSV import command and mailbox creation loop
import-csv $path | foreach {
Set-MsolUser -UserPrincipalName $_.UserPrincipalName -usagelocation “AU”
Set-MsolUserLicense -UserPrincipalName $_.UserPrincipalName -AddLicenses “$server”
}
 
#Result report on licenses assigned to imported users
import-csv $path | Get-MSOLUser | out-gridview


Import-PSSession $SESSION

import-csv $path |foreach {
New-MoveRequest -Identity $_.UserPrincipalName -Remote -RemoteHostName mail.svdpqld.org.au -TargetDeliveryDomain svdpqld.mail.onmicrosoft.com -RemoteCredential $ONPREMCREDS
}