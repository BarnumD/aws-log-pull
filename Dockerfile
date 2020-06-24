FROM mcr.microsoft.com/powershell:7.0.2-ubuntu-18.04

SHELL ["pwsh", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue'; $verbosePreference='Continue';"]

RUN Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
RUN Install-Module -Name AWSPowerShell -MinimumVersion 4.0.6.0;

WORKDIR /app
COPY . /app

VOLUME ["/config"]

ENTRYPOINT [ "pwsh", "-C" ]
CMD [Get-CloudWatchLogs.ps1]