# File name: backup_report_generation.ps1
# Owner:   Gulam Rasool
# Tester:   
# Reviewer:
# Description: This Script will generate backup report for azure vm's and it has capabilities to send mail.
#Required Comonents: - 
#  1:- SendGrid Account on azure to send mail.
#Note:- If Sendgrid Account is not ready Please comment line number 62 to 75.
#  2:- Create Folder with full access where script will copy report file and metioned path on line number 62 against $report variable
#Things No need to change
#Please do not modify email id under From section , email id may based on azure account   
#Uses:-
#.\backup_report_generation.ps1
# Algorithm:
# -----------
#1- It will generate report for single or multile  subscription on Azure
#2. It will send mail via sendgrid to folks
#Variable Detail
#----------------
#$vaults:- Recovery service vault information .
#$containers:- It will contain information about vault which will be allign to Get-AzureRmRecoveryServicesBackupItem command .

 $report= $null
 $report = @()
 $subs = Get-AzureRmSubscription
 foreach ($sub in $subs){
    Select-AzureRmSubscription -Subscription $sub.SubscriptionId
    Write-Host "========================================================================================================="
    Write-Host "Working on Subscription Name :-" $sub.Name
    Write-Host "Working on Subscription Id :-" $sub.SubscriptionId
    Write-Host "========================================================================================================="
        
    $vaults= Get-AzureRmRecoveryServicesVault
    foreach($vault in $vaults){
        Set-AzureRmRecoveryServicesVaultContext -Vault $Vault
        $containers = Get-AzureRmRecoveryServicesBackupContainer -ContainerType AzureVM
        foreach($container in $containers){
            $backup = Get-AzureRmRecoveryServicesBackupItem -Container $container -WorkloadType AzureVM
            $backup_array = ($backup.Name).Split(";")
            $VMName = $backup_array[3]
            $RG= $backup_array[2]
            $vaultname= $vault.Name
            $status = $backup.LastBackupStatus
            $recovery = $backup.LatestRecoveryPoint
            $last= $backup.LastBackupTime
            $policy = $backup.ProtectionPolicyName
            $backup_detail = New-Object psobject
            $backup_detail | Add-Member -MemberType NoteProperty -Name "Report Extration Date" -Value (Get-Date | select -First 1)
            $backup_detail | Add-Member -MemberType NoteProperty -Name "VM Name" -Value $VMName
            $backup_detail | Add-Member -MemberType NoteProperty -Name "Resource Group Name" -Value $RG
            $backup_detail | Add-Member -MemberType NoteProperty -Name " RS Vault Name" -Value $vaultname
            $backup_detail | Add-Member -MemberType NoteProperty -Name "Backup Status" -Value $status
            $backup_detail | Add-Member -MemberType NoteProperty -Name "Recovery Point" -Value $recovery
            $backup_detail | Add-Member -MemberType NoteProperty -Name "Last Bakcup Time" -Value $last
            $backup_detail | Add-Member -MemberType NoteProperty -Name "Policy Name" -Value $policy
            $backup_detail | Add-Member -MemberType NoteProperty -Name "Subscription Name Name" -Value $sub.Name
            $report = $report + $backup_detail
            }
        }
    }
$report | Export-Csv "c:\Backup\Backup.csv" -NoTypeInformation -NoClobber
Write-Output " Program will wait for 20 second to finish Report generation."
Start-Sleep -s 20
Write-Output " Preparing to send mail with backup attachment to $to Receipent"
$user = "azure_0fc2323a953cb53e0d5dcdf48774abc3@azure.com"
$pass =  ConvertTo-SecureString "Azurecloud@321$%" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential $user, $pass
$time = Get-Date -DisplayHint Date
$smtp = "smtp.sendgrid.net"
$from = "No-reply@azureadmin.com"
[string[]]$to= "abc@gmail.com","hdde@wwpdl.vnet.ibm.com","cxy@in.ibm.com"
$sub= "Bakcup report for Nationa Grid By PS Script on $time"
$body = "this tis mail "
$attach = "c:\Backup\Backup.csv"
Send-MailMessage -SmtpServer $smtp -Credential $cred -Port 587  -From $from -To $to -Subject $sub -Body $body -Attachments $attach
Write-Output "================================================================================================================================"
Write-Output "                                            END OF SCRIPT                            "                       
Write-Output "================================================================================================================================"
Write-Output " Backup generation and sending mail has been completed , Please check your inbox if you'r under recepient list"
