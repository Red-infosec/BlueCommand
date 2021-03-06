New-UDPage -Name "EmpireConfiguration" -Icon empire -Endpoint {

  
    $NetworkResources = Get-BSNetworkScanData
    $ValidEmpireNetworkResources = @()

    ForEach($Resource in $NetworkResources)
    {
        if($Resource.isEmpire -eq 'YES')
        {
            $ValidEmpireNetworkResources = $ValidEmpireNetworkResources + $Resource
           
        }
        else
        {
            #NOT EMPIRE SERVER
        }
    }
    $EmpireConfig = Get-BSEmpireConfigData
   


    New-UDInput -Title "Connect to New Empire Server" -Id "EmpireConfiguration" -SubmitText "Connect" -Content {
        New-UDInputField -Type 'textarea' -Name 'EmpireIP' -DefaultValue $Cache:EmpireServer
        New-UDInputField -Type 'textarea' -Name 'EmpirePort' -DefaultValue '1337'
        New-UDInputField -Type 'textarea' -Name 'EmpireToken' -DefaultValue $EmpireConfig.empire_token
    } -Endpoint {
        param($EmpireIP, $EmpirePort, $EmpireToken)
        New-UDInputAction -Toast "Retrieving Empire Configurations!"
        
        $EmpireComputer = $EmpireIP
        
        Write-BSAuditLog -BSLogContent "Empire Configuration: Attempting to Retrieve Configuration from: $EmpireComputer"


        $EmpireConfiguration = Get-EmpireStatus -EmpireBox $EmpireComputer -EmpireToken $EmpireToken -EmpirePort $EmpirePort
        Write-BSEmpireConfigData -BSObject $EmpireConfiguration
        
        $EmpireAgents = Get-EmpireAgents -EmpireBox $EmpireComputer -EmpireToken $EmpireToken -EmpirePort $EmpirePort
        Write-BSEmpireAgentData -BSObject $EmpireAgents

        $EmpireModules = Get-EmpireModules -EmpireBox $EmpireComputer -EmpireToken $EmpireToken -EmpirePort $EmpirePort
        Write-BSEmpireModuleData -BSObject $EmpireModules

        #Update Other Elements
        Sync-UDElement -Id "ExistingEmpireInstance" -Broadcast
        Sync-UDElement -Id "EmpireAgents" -Broadcast
        Sync-UDElement -Id "EmpireModules" -Broadcast

        Write-BSAuditLog -BSLogContent "Empire Configuration: Configuration Retrieval Complete"

    }

  


    New-UDGrid -Title "Existing Empire Instance" -Id "ExistingEmpireInstance" -Headers @("empire_host","version", "api_username", "install_path", "sync_time") -Properties @("empire_host","version", "api_username", "install_path", "sync_time") -Endpoint {
        $JsonData = Get-BSEmpireConfigData
        If ($JsonData.version)
        {
            $Text =  'Empire - Version: ' + ($JsonData.version) +' - User: ' + ($JsonData.api_username)  + ' - Installed: ' + ($JsonData.install_path)    
        }
        else 
        {
            $Text = "No Empire Found - Run Config!"            
        }
        $JsonData | Out-UDGridData
    }

        
    New-UDGrid -Title "Empire Agents" -Id "EmpireAgents" -Headers @("id", "name", "checkin_time","external_ip","hostname","langauge", "langauge_version", "lastseen_time","listener","os_details","username") -Properties @("id", "name", "checkin_time","external_ip","hostname","langauge", "langauge_version", "lastseen_time","listener","os_details","username") -AutoRefresh -Endpoint {
        $JsonData = Get-BSEmpireAgentData
        $JsonData | Out-UDGridData
    }        

    New-UDGrid -Title "Empire Modules" -Id "EmpireModules" -Headers @("Name", "Description", "Author","Language","NeedsAdmin","OpsecSafe") -Properties @("Name", "Description", "Author","Language","NeedsAdmin","OpsecSafe") -AutoRefresh -Endpoint {
        $JsonData = Get-BSEmpireModuleData
        $JsonData | Out-UDGridData
    }      
    
    
}