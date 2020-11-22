# Windows Server run these commands to install the RSAT AD module
Import-Module ServerManager
Add-WindowsFeature -Name "RSAT-AD-PowerShell" –IncludeAllSubFeature

# Win10 run these commands to install the RSAT AD module
Add-WindowsCapability –online –Name “Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0”
Import-Module ActiveDirectory 

# Variables
$euc_domain = "domain.example.com"
$users_path = "OU=Users,OU=Objects-Users,DC=domain,DC=example,DC=com"
$admins_path = "OU=Admins,OU=Objects-Users,DC=domain,DC=example,DC=com"

$user_template = Get-ADUser -Identity "User_Object_Template" -Server $euc_domain -Properties memberof
$admin_template = Get-ADUser -Identity "User_Object_Admin_Template" -Server $euc_domain  -Properties memberof

$users_list = get-aduser -SearchBase $users_path  -Server $euc_domain -Filter * | Select-Object sAMAccountName
$admins_list = get-aduser -SearchBase $admins_path -Server $euc_domain -Filter * | Select-Object sAMAccountName | ForEach-Object { $_ -replace "_admin", "" }

$password = "P@ssw0rd" | ConvertTo-SecureString -AsPlainText -Force

$DLMembers = Import-Csv c:\users\aaperauch_admin\Desktop\pso-amer-euc-all.csv

foreach ($m in $DLMembers) {
    $username = $m.Email -replace "@example.com", ""

    # Users
    if ($users_list -imatch $username) {
        Write-Host "User account exists.  Skipping $username."
    }
    else {
        New-ADUser -Enabled $true -Name ($m.First + " " + $m.Last) -GivenName $($m.First) -Surname $($m.Last) -UserPrincipalName ($username + "@euc.vmwarepso.org") -EmailAddress ($username + "@vmwarepso.org") -SamAccountName $username -Path $users_path -AccountPassword $password -ChangePasswordAtLogon $true -Server $euc_domain
        $_
    }

    # Add new user to same user groups as user template
    $user_template | Select-Object -ExpandProperty memberof | Add-ADGroupMember -Members $username -Server $euc_domain 

    #Admins
    if ($admins_list -imatch $username) {
        Write-Host "Admin account exists.  Skipping $username."
    }
    else {
        New-ADUser -Enabled $true -Name ($m.First + " " + $m.Last) -GivenName $m.First -Surname $m.Last -UserPrincipalName ($username + "_admin@euc.vmwarepso.org") -EmailAddress ($username + "_admin@vmwarepso.org") -SamAccountName ($username + "_admin") -Path $admins_path -AccountPassword $password -ChangePasswordAtLogon $true -Server $euc_domain
    }

    # Add new user to same user groups as user template
    $admin_template | Select-Object -ExpandProperty memberof | Add-ADGroupMember -Members $($username + "_admin") -Server $euc_domain
}

Write-Host "Original users count:   $($users_list.count)."
Write-Host "Original admins acount: $($admins_list.count)."

$users_list = get-aduser -SearchBase $users_path  -Server euc.vmwarepso.org -Filter * | Select-Object sAMAccountName
$admins_list = get-aduser -SearchBase $admins_path -Server euc.vmwarepso.org -Filter * | Select-Object sAMAccountName | ForEach-Object { $_ -replace "_admin", "" }

Write-Host "New users count:   $($users_list.count)."
Write-Host "New admins acount: $($admins_list.count)."

# Must run these commands from Exchange Management Shell
Read-Host "Enter domain admin credentials to enable mailboxes for newly created users on Exchange.  Press any key to continue"

# Establish remote PS session
$creds = Get-Credential
$exch01 = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://exchange-server-01.example.com/powershell/ -Authentication Kerberos -Credential $creds
Import-PSSession $exch01 -DisableNameChecking

# Ensure entire AD forest is searched
Set-ADServerSettings -ViewEntireForest $true

# Enable mailbox for all user accounts in the specifiec OU that do not have a mailbox already
Get-User -OrganizationalUnit $users_path -IgnoreDefaultScope -RecipientTypeDetails user -ResultSize unlimited | Enable-Mailbox 
Get-User -OrganizationalUnit $admins_path -IgnoreDefaultScope -RecipientTypeDetails user -ResultSize unlimited | Enable-Mailbox 

# Remmove remote PS session
Remove-PSSession $exch01