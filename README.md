# AWS-Log-Pull
Pulls logs from Cloudwatch using powershell.  Outputs as either powershell object or json.

## Docker build
```
git clone https://github.com/BarnumD/aws-log-pull.git
cd aws-log-pull
docker build -t aws-log-pull .
```

## Usage
Start with a reasonable startTime (a couple of hours), or you'll be pulling lots of logs.  A cache will then be built of the last log event time.  You can then remove the startTime parameter and only pull the latest events. startTime should be queried in GMT time.
```
docker run -v aws-log-pull-config:/config aws-log-pull ./Get-CloudWatchLogs.ps1 -accessKey [aws_access_key] -secretKey [aws_secret_key] -jsonout -startTime 1577883600000
```
You can then remove the startTime parameter and only pull the latest events.
```
docker run -v aws-log-pull-config:/config aws-log-pull ./Get-CloudWatchLogs.ps1 -accessKey [aws_access_key] -secretKey [aws_secret_key] -jsonout
```

A config directory is used to store a state file.  Use docker volumes or choose a folder to store the config directory in in order to maintain state.
