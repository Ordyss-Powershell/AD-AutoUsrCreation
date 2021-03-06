﻿#Script to create multiple users at once

#Import File Module
Import-Module 'C:\Users\buu_s\OneDrive\Documents\Visual Studio 2015\Projects\Powershell\Scripts\PowerShellProject1\PowerShellProject1\Import-File.psm1'

#Variable that holds CSV file location from file picker
$path = Get-File -initialDirectory “c:\"

#Query Server to use if wanted
$server = Read-Host "Please select you wish to create user on, or if want to use local server, leave blank"

#Create users from CSV file
import-csv $path |foreach {
New-ADUser -server $server -SamAccountName $_.SAMAccountName -name $_.DisplayName -UserPrincipalName $_.UserPrincipalName -GivenName $_.FirstName -Surname $_.LastName -DisplayName $_.DisplayName -Description $_.Description -Path $_.Path
Set-ADAccountPassword -server $server -Identity $_.SAMAccountName -Reset -NewPassword (ConvertTo-SecureString –String $_.AccountPassword -AsPlainText -Force)
}

#Add to Groups Section

$addgroup = Read-host "Do these users require to be added to groups? y/n"

 If ($addgroup -eq 'y') {
 $addinggroups = Read-Host "Is it in the same file, a different file, copy from another user or do you want to input it manually?
 s = Same File
 d = Different File
 c = Copy User
 m = Manual Entry
 s/d/c/m
 "
If ($addinggroups -eq 'd' ){
$path2 = Get-File -initialDirectory “c:\"
import-csv $path2 |foreach {
Add-ADGroupMember -Identity $_.group -Members $_.SAMAccountName
}
}
elseif ($addinggroups -eq 'c') {
$copy = Read-host "Enter username to copy from: "
import-csv $path |foreach {
# copy-paste process. Get-ADuser membership     | then selecting membership                       | and add it to the second user
get-ADuser -identity $copy -properties memberof | select-object memberof -expandproperty memberof | Add-AdGroupMember -Members $_.SAMAccount
}
}
elseif ($addinggroups -eq 'm') {
$groupadd = Read-host "Please specify the groups to be added:"
import-csv $path |foreach {
Add-ADGroupMember -Identity $groupadd -Members $_.SAMAccountName
}
}
elseif ($addinggroups -eq 's') {
import-csv $path |foreach {
Add-ADGroupMember -Identity $_.group -Members $_.SAMAccountName
}
}
}
else {
Write-host "Skipping Group Section"
}

#Mailbox Creation Section
$createmailbox = Write-Host "Does user require a mailbox? y/n"

If ($createmailbox -eq 'y'){
$localexchnage = Write-Host "Please specifcy the server that local exchange authenticates to:"
$localexchnagesession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$($localexchange)/PowerShell/ -Authentication Kerberos
Import-PSSession $localexchnagesession
import-csv $path |foreach {
Enable-Mailbox $_.UserPrincipalName
}
Remove-PSSession $localexchnagesession

#Office 365 Move

$O365mailbox = Read-Host "Do you use O365? y/n"

If ($o365mailbox -eq 'y'){
#Credentials to login servers
$O365CREDS = Get-Credential -Message "O365 Crednetials"
$ONPREMCREDS = Get-Credential -Message "On Premise Credentials"

#Dirsync
$DirsyncSever = Read-Host "Please specify your Dirsync server"
Invoke-Command -ComputerName $DirsyncSever -ScriptBlock { 
Import-Module dirsync;Write-Host "Importing Dirsync Module on $(hostname)" -ForegroundColor Cyan
Start-OnlineCoexistenceSync;Write-Host "Starting Online Coexistence Sync (dirsync) on $(hostname)" -ForegroundColor Cyan
}


#Connect to O365
Connect-MsolService -Credential $O365CREDS

#Check if user is in O365
[:Check_User]
do {
Import-Csv $path | foreach {
Get-MsolUser -UserPrincipalName $_.UserprincipalName
} 


#Dirsync
Invoke-Command -ComputerName $DirsyncSever -ScriptBlock { 
Import-Module dirsync;Write-Host "Importing Dirsync Module on $(hostname)" -ForegroundColor Cyan
Start-OnlineCoexistenceSync;Write-Host "Starting Online Coexistence Sync (dirsync) on $(hostname)" -ForegroundColor Cyan
}
} while {"Does not exist"}

#Import Exchange Module
$O365SESSION = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Credential $O365CREDS -Authentication Basic -AllowRedirection

#Window with list of available 365 licenses and their names
Get-MsolAccountSku | out-gridview
 
#Input window where you provide the license package’s name
$o365license = read-host ‘Provide licensename (AccountSkuId)’
 
#CSV import command and mailbox creation loop
import-csv $path | foreach {
Set-MsolUser -UserPrincipalName $_.UserPrincipalName -usagelocation “AU”
Set-MsolUserLicense -UserPrincipalName $_.UserPrincipalName -AddLicenses “$o365license”
}
 
#Result report on licenses assigned to imported users
import-csv $path | Get-MSOLUser | out-gridview

#Specify Move request Server
$remotehost = Read-Host "Exchange Remote Address:"
$TargetDomain = Read-Host "O365 Delivery Domain:"

Import-PSSession $O365SESSION

import-csv $path |foreach {
New-MoveRequest -Identity $_.UserPrincipalName -Remote -RemoteHostName $remotehost -TargetDeliveryDomain $TargetDomain -RemoteCredential $ONPREMCREDS

}
}
else {
Write-Host "Skipping O365 Export"
}
}
else {
Write-Host "Skipping Mailbox Creation"
}


