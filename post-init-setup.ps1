<#
    .SYNOPSIS
        Finalize the setup after the execution of the 'azd init' command or the fork of the GitHub repository.
    .DESCRIPTION
        - Get default environment name (from the 'config.json' file under the '.azure' folder)
        - Create an Azure AD app registration to manage the solution deployment to the considered Azure subscription
        - Create an Azure AD app registration to interact with the Dataverse environment
        - Create a Dataverse environment
        - Add the Azure AD app registration as an application user to the Dataverse environment
        - Update the environment definition ('env' file under the '.azure' folder)
    .INPUTS
        None.
    .OUTPUTS
        None.
    .EXAMPLE
        PS> .\post-init-setup.ps1
    .LINK
        https://github.com/rpothin/servicebus-csharp-function-dataverse
    .NOTES
        This script will first run some validations then do the steps described in the "Description" section.
#>

[CmdletBinding()] param ()

# Variables initialization
$azureEnvironmentsConfigurationFilePath = ".\.azure\config.json"

# Validate that the required CLI are installed
## Azure CLI - https://learn.microsoft.com/en-us/cli/azure/
az version

## Azure Developer CLI - https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/overview
azd version

## Power Platform CLI -https://learn.microsoft.com/en-us/power-platform/developer/cli/introduction
pac help

# Validate the connections
## Azure CLI
Write-Verbose "Checking Azure CLI connection status..."
$azureSignedInUserId = az ad signed-in-user show --query 'id'

if ([string]::IsNullOrEmpty($azureSignedInUserId)) {
    Write-Verbose "No signed in user found for Azure CLI..."
    az login
}

Write-Verbose "Connected to Azure CLI!"

## Power Platform CLI
Write-Verbose "Checking Power Platform CLI connection status..."
$pacProfiles = pac auth list

if ($pacProfiles -eq "No profiles were found on this computer. Please run 'pac auth create' to create one.") {
    Write-Verbose "No profile found for Power Platform CLI..."
    pac auth create
}

Write-Verbose "Connected to Power Platform CLI!"

# Get default environment name
## Validate there is a 'config.json' file under a '.azure' folder
Write-Verbose "Checking the presence of a 'config.json' file under a '.azure' folder..."
if (!(Test-Path $azureEnvironmentsConfigurationFilePath)) {
    Write-Verbose "No 'config.json' file found under a '.azure' folder..."
    azd env new
}

## Get default environment from 'config.json' file under '.azure' folder
Write-Verbose "Getting the default environment the 'config.json' file under the '.azure' folder..."
$azureEnvironmentsConfiguration = Get-Content $azureEnvironmentsConfigurationFilePath | ConvertFrom-Json
$azureDefaultEnvironmentName = $azureEnvironmentsConfiguration.defaultEnvironment

Write-Host "Default environment: $azureDefaultEnvironmentName"

$response = Read-Host "Do you want to use the above environment? (Y/N)"

if (!($response.ToLower() -eq "y")) {
    Write-Host "Use the 'azd env select' command to set the default environment you'd like to use and re-run this script."
    Exit
}

# Create an Azure AD app registration to manage the solution deployment to the considered Azure subscription
$azureDeploymentAppRegistrationName = "sp-$azureDefaultEnvironmentName-azure"

## Check if an Azure AD app registration with the same name exists, if not create one
### To continue...