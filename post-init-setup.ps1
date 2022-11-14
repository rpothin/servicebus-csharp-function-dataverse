<#
    .SYNOPSIS
        Finalize the setup after the execution of the 'azd init' command or the fork of the GitHub repository.
    .DESCRIPTION
        - Get default environment name (from the 'config.json' file under the '.azure' folder)
        - Get the Azure subscription configured for the default environment (from the '.env' file)
        - Create an app registration to manage the solution deployment to the considered Azure subscription
        - Create an app registration to interact with the Dataverse environment
        - Create a Dataverse environment
        - Add the app registration as an application user to the Dataverse environment
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
        This script:
        - need to be exectuded at the root level of the "Azure Developer CLI" compatible folder
        - will first run some validations then do the steps described in the "Description" section
#>

[CmdletBinding()] param ()

#region Variables initialization


$azureEnvironmentsFolderBasePath = ".\.azure\"
$azureEnvironmentsConfigurationFilePath = $azureEnvironmentsFolderBasePath + "config.json"
$environmentConfigurationFileName = "\.env"

$azureSubscriptionIdEnvironmentVariableName = "AZURE_SUBSCRIPTION_ID"

$rolesToAssignOnAzureSubscription = @("Contributor", "User Access Administrator")

#endregion Variables initialization

#region Validate that the required CLI are installed

# Azure CLI - https://learn.microsoft.com/en-us/cli/azure/
Write-Verbose "Checking if Azure CLI is installed..."
try {
    $azureCliVersion = az version
    Write-Verbose "👍🏼 Azure CLI is installed!"
} catch {
    Write-Error -Message "Error checking if Azure CLI is installed" -ErrorAction Stop
}

# Azure Developer CLI - https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/overview
Write-Verbose "Checking if Azure Developer CLI is installed..."
try {
    $azureDeveloperCliVersion = azd version
    Write-Verbose "👍🏼 Azure Developer CLI is installed!"
} catch {
    Write-Error -Message "Error checking if Azure Developer CLI is installed" -ErrorAction Stop
}

# Power Platform CLI -https://learn.microsoft.com/en-us/power-platform/developer/cli/introduction
Write-Verbose "Checking if Power Platform CLI is installed..."
try {
    $powerPlatformCliVersion = pac help
    Write-Verbose "👍🏼 Power Platform CLI is installed!"
} catch {
    Write-Error -Message "Error checking if Power Platform CLI is installed" -ErrorAction Stop
}

#endregion Validate that the required CLI are installed

#region Validate the connections

# Azure CLI
Write-Verbose "Checking Azure CLI connection status..."
$azureSignedInUser = az ad signed-in-user show --query '[id, mail]' --output tsv
$azureSignedInUserMail = $azureSignedInUser[1]

if ([string]::IsNullOrEmpty($azureSignedInUserMail)) {
    Write-Verbose "No signed in user found for Azure CLI. Please login..."
    $azureCliLoginResult = az login
}

Write-Verbose "👍🏼 Connected to Azure CLI!"

# Power Platform CLI
Write-Verbose "Checking Power Platform CLI connection status..."
$pacProfiles = pac auth list

if ($pacProfiles -eq "No profiles were found on this computer. Please run 'pac auth create' to create one.") {
    Write-Verbose "No profile found for Power Platform CLI. Please create a profile..."
    $powerPlatformCliAuthCreateResult = pac auth create
}

Write-Verbose "👍🏼 Connected to Power Platform CLI!"

#endregion Validate the connections

#region Get default environment name

# Validate there is a 'config.json' file under a '.azure' folder
Write-Verbose "Checking the presence of a 'config.json' file under a '.azure' folder..."
if (!(Test-Path $azureEnvironmentsConfigurationFilePath)) {
    Write-Verbose "No 'config.json' file found under a '.azure' folder. Please configure an environment..."
    azd env new
}

# Get default environment from 'config.json' file under '.azure' folder
Write-Verbose "Getting the default environment the 'config.json' file under the '.azure' folder..."
try {
    $azureEnvironmentsConfiguration = Get-Content $azureEnvironmentsConfigurationFilePath | ConvertFrom-Json
    $azureDefaultEnvironmentName = $azureEnvironmentsConfiguration.defaultEnvironment
} catch {
    Write-Error -Message "Error getting the default environment name from the 'config.json' file under the '.azure' folder" -ErrorAction Stop
}

Write-Host "Default environment: $azureDefaultEnvironmentName" -ForegroundColor Blue

$response = Read-Host "Do you want to use the above environment? (Y/N)"

if (!($response.ToLower() -eq "y")) {
    Write-Host "Use the 'azd env select' command to set the default environment you'd like to use and re-run this script."
    Exit
}

#endregion Get default environment name

#region Get default environment details

# Validate there is a '.env' file under the default environment configuration folder
Write-Verbose "Checking the presence of a '.env' file under the $azureDefaultEnvironmentName configuration folder..."
$azureDefaultEnvironmentConfigurationFilePath = $azureEnvironmentsFolderBasePath + $azureDefaultEnvironmentName + $environmentConfigurationFileName
if (!(Test-Path $azureDefaultEnvironmentConfigurationFilePath)) {
    Write-Error -Message "No '.env' file under the $azureDefaultEnvironmentName configuration folder" -ErrorAction Stop
}

# Get default environment details from '.env' file under the default environment configuration folder
Write-Verbose "Getting the default environment details from '.env' file under the default environment configuration folder..."
try {
    $azureDefaultEnvironmentDetails = Get-Content $azureDefaultEnvironmentConfigurationFilePath
    
    foreach ($azureDefaultEnvironmentDetail in $azureDefaultEnvironmentDetails) {
        $azureDefaultEnvironmentDetailSplitted = $azureDefaultEnvironmentDetail.Split('=')

        if ($azureDefaultEnvironmentDetailSplitted[0] -eq $azureSubscriptionIdEnvironmentVariableName) {
            $azureDefaultEnvironmentSubscriptionId = $azureDefaultEnvironmentDetailSplitted[1]
        }
    }
} catch {
    Write-Error -Message "Error getting the default environment details from '.env' file under the default environment configuration folder" -ErrorAction Stop
}

#endregion Get default environment details

#region Validate the Azure subscription configured on the default environment

# Get the name of the Azure subscription configured for the default environment
$azureDefaultEnvironmentSubscriptionDisplayName = az account subscription show --id $azureDefaultEnvironmentSubscriptionId --query 'displayName' --output tsv

Write-Host "Default environment Azure subscription ID: '$azureDefaultEnvironmentSubscriptionDisplayName' ($azureDefaultEnvironmentSubscriptionId)" -ForegroundColor Blue

$response = Read-Host "Do you want to use the above Azure subscription? (Y/N)"

if (!($response.ToLower() -eq "y")) {
    Write-Host "Use the 'azd env set' command to set the Azure subscription you'd like to use with the default environment and re-run this script."
    Exit
}

#endregion Validate the Azure subscription configured on the default environment

#region Create a service principal to manage the solution deployment to the considered Azure subscription

# Validate the account to use for the creation of the service principal to manage the solution deployment to the considered Azure subscription
Write-Host "Account considered for creation of the service principal to manage the solution deployment to the considered Azure subscription: $azureSignedInUserMail" -ForegroundColor Blue
$response = Read-Host "Do you want to use this account for this operation? (Y/N)"

if (!($response.ToLower() -eq "y")) {
    Write-Host "Connection to Azure CLI with the account you want to use for this operation..."
    $azureCliLoginResult = az login
}

# Check if an app registration with the same name exists, if not create one
$azureDeploymentAppRegistrationName = "sp-$azureDefaultEnvironmentName-azure"

Write-Verbose "Checking if an '$azureDeploymentAppRegistrationName' app registration already exist in..."
$azureDeploymentAppRegistrationId = az ad app list --filter "displayName eq '$azureDeploymentAppRegistrationName'" --query [].appId --output tsv

if ([string]::IsNullOrEmpty($azureDeploymentAppRegistrationId)) {
    Write-Verbose "No '$azureDeploymentAppRegistrationName' app registration found. Creating app registration..."
    $azureDeploymentAppRegistrationId = az ad app create --display-name $azureDeploymentAppRegistrationName --query appId --output tsv
    Write-Verbose "👍🏼 '$azureDeploymentAppRegistrationName' app registration created!"
} else {
    Write-Verbose "Existing '$azureDeploymentAppRegistrationName' app registration found."
}

# Check if a service principal with the same name exists, if not create one
Write-Verbose "Checking if a '$azureDeploymentAppRegistrationName' service principal already exist in..."
$azureDeploymentServicePrincipalId = az ad sp list --filter "appId eq '$azureDeploymentAppRegistrationId'" --query [].id --output tsv

if ([string]::IsNullOrEmpty($azureDeploymentServicePrincipalId)) {
    Write-Verbose "No '$azureDeploymentAppRegistrationName' service principal found. Creating service principal..."
    $azureDeploymentServicePrincipalId = az ad sp create --id $azureDeploymentAppRegistrationId --query id --output tsv
    Write-Verbose "👍🏼 '$azureDeploymentAppRegistrationName' service principal created!"
} else {
    Write-Verbose "Existing '$azureDeploymentAppRegistrationName' service principal found."
}

# Create role assignments for the service principal on the considered Azure subscription
Write-Verbose "Role assignments creation for the '$azureDeploymentAppRegistrationName' service principal on the '$azureDefaultEnvironmentSubscriptionDisplayName' Azure subscription..."
foreach ($roleToAssignOnAzureSubscription in $rolesToAssignOnAzureSubscription) {
    Write-Verbose "Creation of an assignment for the role '$roleToAssignOnAzureSubscription'..."
    $roleAssignmentCreationResult = az role assignment create --subscription $azureDefaultEnvironmentSubscriptionId --role $roleToAssignOnAzureSubscription --assignee-object-id $azureDeploymentServicePrincipalId --assignee-principal-type ServicePrincipal
    Write-Verbose "👍🏼 '$roleToAssignOnAzureSubscription' role has been assigned!"
}

# Add service principal name as an environment variable to the default environment
Write-Verbose "Add service principal name to the '.env' file of the default environment..."
azd env set SERVICE_PRINCIPAL_NAME $azureDeploymentAppRegistrationName
Write-Verbose "👍🏼 Service principal name added to the '.env' file of the default environment!"

#endregion Create a service principal to manage the solution deployment to the considered Azure subscription

#region Get Dataverse environment URL

# Todo
# + set DATAVERSE_ENV_URL env variable with azd env set command

#endregion Get Dataverse environment URL

#region Create a service principal to be assigned as an application user to the considered Dataverse environment

# Todo
# + Generate a secret
# + Set DATAVERSE_CLIENT_ID and DATAVERSE_CLIENT_SECRET env variables with azd env set command

#endregion Create a service principal to be assigned as an application user to the considered Dataverse environment

#region Assign service principal as an application user to the considered Dataverse environment

# Todo
# Use pac admin assign-user command

#endregion Assign service principal as an application user to the considered Dataverse environment