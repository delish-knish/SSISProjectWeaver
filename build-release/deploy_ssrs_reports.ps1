# Script Parameters
Param(
    [string]$ReportServerUri = "http://localhost/ReportServer",
    [string]$RdlFolder = "C:\vsts-rel\SSISProjectWeaver-CI\44\reports",
    [string]$RsPath = "/",
    [string]$RsFolderName = "SSISProjectWeaver",
    [string]$DatasourceName = "SSISExecutionManager",
    [switch]$CleanReportServer
)

#Delete all objects
if ($CleanReportServer) {
    Get-RsCatalogItems -ReportServerUri http://localhost/ReportServer -RsFolder '/' | Remove-RsCatalogItem -ReportServerUri http://localhost/ReportServer -Verbose -Confirm:$false
}

#Create SSRS folder  TODO: Check for folder existence
$targetFolder = Get-RsFolderContent -RsFolder $RsPath | Where-Object { $_.Name -eq $RsFolderName }
if ($targetFolder -eq $null)
{
    New-RsFolder -ReportServerUri $ReportServerUri -Path $RsPath -Name $RsFolderName -Verbose
}

CD $RdlFolder

$Destination = $RsPath + $RsFolderName

#Deploy datasource
Dir $RdlFolder -Filter *.rds | Write-RsCatalogItem -ReportServerUri $ReportServerUri -Destination $Destination -OverWrite -Verbose

#Deploy all reports to single folder
Write-RsFolderContent -ReportServerUri $ReportServerUri -Path $RdlFolder -Destination $Destination -Verbose -Overwrite

$DataSourcePath = $Destination + "/" + $DatasourceName

# Set report datasource
Get-RsCatalogItems -ReportServerUri $reportServerUri -RsFolder $Destination | Where-Object TypeName -eq 'Report' | ForEach-Object {
    $dataSource = Get-RsItemReference -ReportServerUri $ReportServerUri -Path $_.Path
    Write-Output $_.Path
    if ($dataSource -ne $null) {
       Set-RsDataSourceReference -ReportServerUri $ReportServerUri -Path $_.Path -DataSourceName $dataSource.Name -DataSourcePath $DataSourcePath
        Write-Output "Changed datasource $($dataSource.Name) set to $DataSourcePath on report $($_.Path) "
    }
    else {
         Write-Warning "Report $($_.Path) does not contain an datasource"
    }
}
