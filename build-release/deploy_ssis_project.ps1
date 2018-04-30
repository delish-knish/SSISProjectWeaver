# Deploy SSIS projects to a target server
# Execution Example;
# .\deploy_ssis_project.ps1 -TargetServerName "localhost" -TargetFolderName "SSIS Catalog Folder Name" -ProjectFilePath "D:\source\repos\ssis_project\bin\Release\ssis_project.ispac" -EnvironmentNameme "QA"

# Script Parameters
Param(
    [string]$TargetServerName = "localhost",
    [string]$TargetFolderName = "SSIS Project Weaver Example Projects",
    [string]$ProjectFilePath = "\\build-share\SSISExecutionManager.ispac",
    [string]$ProjectName = "Sample",
    [string]$EnvironmentName = "QA"
)

Write-Host("Parameters:")
Write-Host(" -TargetServerName: " + $TargetServerName)
Write-Host(" -TargetFolderName: " + $TargetFolderName)
Write-Host(" -ProjectFilePath: " + $ProjectFilePath)
Write-Host(" -ProjectName: " + $ProjectName)
Write-Host(" -EnvironmentName: " + $EnvironmentName)

# Set up the variables
[string]$SSISNamespace = "Microsoft.SqlServer.Management.IntegrationServices"
[string]$SSISCatalog = "SSISDB"

# Load the IntegrationServices assembly
$loadStatus = [System.Reflection.Assembly]::Load("Microsoft.SQLServer.Management.IntegrationServices, "+
    "Version=14.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91, processorArchitecture=MSIL")

# Create a connection to the server
$sqlConnectionString = `
    "Data Source=" + $TargetServerName + ";Initial Catalog=master;Integrated Security=SSPI;"
$sqlConnection = New-Object System.Data.SqlClient.SqlConnection $sqlConnectionString

# Create the Integration Services object
$integrationServices = New-Object $SSISNamespace".IntegrationServices" $sqlConnection

# Get the Integration Services catalog
$catalog = $integrationServices.Catalogs[$SSISCatalog]
if (!$catalog) {
    Write-Error("Cannot find the SSIS DB Catalog.")
    exit 1
}

# Create the target folder
$folder = $catalog.Folders[$TargetFolderName]
if (!$folder) {
    Write-Host "Creating folder ..." 
    $folder = New-Object $SSISNamespace".CatalogFolder" ($catalog, $TargetFolderName, "Folder description")
    $folder.Create()
}

Write-Host "Deploying " $ProjectName " project ..."
# Read the project file and deploy it
[byte[]] $projectFile = [System.IO.File]::ReadAllBytes($ProjectFilePath)
$folder.DeployProject($ProjectName, $projectFile)


$environment = $folder.Environments[$EnvironmentName]
if (!$environment) {
    Write-Host "Creating environment ..." 
    $environment = New-Object "$SSISNamespace.EnvironmentInfo" ($folder, $EnvironmentName, $EnvironmentName)
    $environment.Create()            
}

$project = $folder.Projects[$ProjectName]
$ref = $project.References[$EnvironmentName, $folder.Name]

if (!$ref) {
    # making project refer to this environment
    Write-Host "Adding environment reference to project ..."
    $project.References.Add($EnvironmentName, $folder.Name)
    $project.Alter() 
}

Write-Host "Done."