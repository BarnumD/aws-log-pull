#!/usr/bin/pwsh -noprofile
[CmdletBinding(SupportsShouldProcess=$true)]
param (
  [string]$accessKey,
  [string]$secretKey,
  [string]$logGroupName,
  [string]$region        = 'us-east-1',
  [string]$startTime     = '0000000000001',# In epoch milliseconds.  Generallly stored in GMT, so use GMT time in your query.
  [string]$configDir     = '/config',
  [switch]$jsonOut
)

#####################################################
###VVVVVVVVVVVVV Import modules VVVVVVVVVVVVVV#######
Import-Module ./Functions/JSON-To-Hashtable.psm1
Import-Module -Name AWSPowerShell

$returnedEvents = @()
$logGroups = @()
$dateTimeNowEpoch = [Math]::Floor([decimal](Get-Date(Get-Date).ToUniversalTime()-uformat "%s"))
$dateTimeBeforeEpoch = [Math]::Floor([decimal](Get-Date((Get-Date).AddHours(-24)).ToUniversalTime()-uformat "%s"))
$cloudwatchLogState = @{"LastEventTimeByGroup" = @{}}
$calculatedStartTime = $startTime

#We store last event timestamp information in a file so we can use it on subsequent runs.
#Obtain the cached state file
If (Test-Path "$configDir/cloudwatchlogs.statefile"){
  $cloudwatchLogState = (Get-Content "$configDir/cloudwatchlogs.statefile"| ConvertFrom-Json| ConvertTo-HashTable)
}


#Create a list of log groups to be processed.
# If LogGroupName is specified, use that.  Otherwise, get all the logs groups
If ($logGroupName){
  $logGroups = @($logGroupName)
}else{
  $nextToken = 'initial'
  
  While ($nextToken){
    If ($nextToken -eq 'initial') {$nextToken = $null}

    ForEach ($result in (Get-CWLLogGroup -Region $region -AccessKey $accessKey -SecretKey $secretKey -NextToken $nextToken)){
      $logGroups += $result.LogGroupName
    }
  }
}

#Filter log events by date and return.
ForEach ($logGroupName in $logGroups){
  $nextToken = 'initial'

  #Determine startTime.
  If ($startTime -eq '0000000000001'){ #No startTime was passed.  See if there is a cached startTime instead.
    If (($cloudwatchLogState) -And ($cloudwatchLogState.LastEventTimeByGroup) -And ($cloudwatchLogState.LastEventTimeByGroup."$logGroupName")){
      #Found a valid start time from cache.  Add one second.
      $calculatedStartTime = (($cloudwatchLogState.LastEventTimeByGroup."$logGroupName") + 1).tostring()
    }else{
      #There was no valid cache.  Use default start time.
    }
  }

  $storedStartTime = $calculatedStartTime
  While ($nextToken){
    If ($nextToken -eq 'initial') {$nextToken = $null}
    ForEach ($result in (Get-CWLFilteredLogEvent -LogGroupName $logGroupName -Region $region -AccessKey $accessKey -SecretKey $secretKey -NextToken $nextToken -StartTime $calculatedStartTime )){
      $nextToken = $result.NextToken

      #Tabulate each result into a table that we'll output later.
      ForEach ($event in $result.Events){
        $calculatedStartTime = $event.TimeStamp + 1

        $returnedEvent = @{
          "LogGroupName"  = $logGroupName
          "LogStreamName" = $event.LogStreamName
          "EventId"       = $event.EventId
          "IngestionTime" = $event.IngestionTime
          "Message"       = $event.Message
          "Timestamp"     = $event.Timestamp
        }

        #Output to console
        If ($jsonOut){
          $returnedEvent | ConvertTo-Json
        }Else{
          $returnedEvent
        }

        #Update the state with the timestamp of this event.
        if ($cloudwatchLogState.LastEventTimeByGroup."$logGroupName"){
          If ($event.Timestamp -gt $cloudwatchLogState.LastEventTimeByGroup."$logGroupName"){
            $cloudwatchLogState.LastEventTimeByGroup."$logGroupName" = $event.Timestamp
          }
        }else{
          $cloudwatchLogState.LastEventTimeByGroup["$logGroupName"] = $event.Timestamp
        }
      }
    }
  }
  $calculatedStartTime = $storedStartTime
}

#Output state to statefile
$cloudwatchLogState| ConvertTo-Json| Out-File "/$configDir/cloudwatchlogs.statefile"