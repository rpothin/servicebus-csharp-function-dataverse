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
        This script will first run some validations then do the steps described in the "Description" section
#>

[CmdletBinding()] param ()

#region Variables initialization

$azureEnvironmentsFolderBasePath = "$PSScriptRoot\..\.azure\"
$azureEnvironmentsConfigurationFilePath = $azureEnvironmentsFolderBasePath + "config.json"
$environmentConfigurationFileName = "\.env"

$azureSubscriptionIdEnvironmentVariableName = "AZURE_SUBSCRIPTION_ID"

$rolesToAssignOnAzureSubscription = @("Contributor", "User Access Administrator")

$dataverseEnvironmentConfigurationFilePath = "$PSScriptRoot\..\.dataverse\environment-configuration.json"

$dataverseSecurityRoleNameForApplicationUser = "Service Reader"

#endregion Variables initialization

#region Validate that the required CLI are installed

# Azure CLI - https://learn.microsoft.com/en-us/cli/azure/
Write-Verbose "Checking if Azure CLI is installed..."
$azureCliVersion = az version

if ($?) {
    Write-Verbose "👍🏼 Azure CLI is installed!"
} else {
    az version
    Write-Error -Message "Azure CLI does not seem installed. Please install it to continue: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli" -ErrorAction Stop
}

# Azure Developer CLI - https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/overview
Write-Verbose "Checking if Azure Developer CLI is installed..."
$azureDeveloperCliVersion = azd version

if ($?) {
    Write-Verbose "👍🏼 Azure Developer CLI is installed!"
} else {
    azd version
    Write-Error -Message "Azure Developer CLI does not seem installed. Please install it to continue: https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd" -ErrorAction Stop
}

# Power Platform CLI -https://learn.microsoft.com/en-us/power-platform/developer/cli/introduction
Write-Verbose "Checking if Power Platform CLI is installed..."
$powerPlatformCliVersion = pac help

if ($?) {
    Write-Verbose "👍🏼 Power Platform CLI is installed!"
} else {
    $powerPlatformCliVersion
    Write-Error -Message "Power Platform CLI does not seem installed. Please install it to continue: https://learn.microsoft.com/en-us/power-platform/developer/cli/introduction#install-power-platform-cli-for-windows" -ErrorAction Stop
}

#endregion Validate that the required CLI are installed

#region Validate the connections

# Azure Developer CLI - Authentication delegated to Azure CLI
azd config set auth.useAzCliAuth true

# Azure CLI
Write-Verbose "Checking Azure CLI connection status..."
$azureSignedInUserMail = ""
try {
    $azureSignedInUser = az ad signed-in-user show --query '[id, mail]' --output tsv
    $azureSignedInUserMail = $azureSignedInUser[1]
} catch {
    # Do nothing
}

if ([string]::IsNullOrEmpty($azureSignedInUserMail)) {
    Write-Host "No signed in user found for Azure CLI. Please login..." -ForegroundColor Blue
    $azureCliLoginResult = az login --use-device-code
    
    try {
        $azureSignedInUser = az ad signed-in-user show --query '[id, mail]' --output tsv
        $azureSignedInUserMail = $azureSignedInUser[1]
    } catch {
        Write-Error -Message "Error while trying to get the email of the user connected to Azure CLI." -ErrorAction Stop
    }
}

Write-Verbose "👍🏼 Connected to Azure CLI!"

# Azure Developer CLI - Check connection status
Write-Verbose "Checking Azure Developer CLI connection status..."
$azdLoginCheckStatusResult = azd login --check-status

if ($azdLoginCheckStatusResult -eq "Logged in to Azure.") {
    Write-Verbose "👍🏼 Connected to Azure Developer CLI!"
} else {
    Write-Error -Message "No user connected to Azure Developer CLI." -ErrorAction Stop
}

# Power Platform CLI
Write-Verbose "Checking Power Platform CLI connection status..."
$pacProfiles = pac auth list

if ($pacProfiles -eq "No profiles were found on this computer. Please run 'pac auth create' to create one.") {
    Write-Host "No profile found for Power Platform CLI. Please create a profile..." -ForegroundColor Blue
    pac auth create --deviceCode
}

Write-Verbose "👍🏼 Connected to Power Platform CLI!"

#endregion Validate the connections

#region Get default environment name

# Validate there is a 'config.json' file under a '.azure' folder
Write-Verbose "Checking the presence of a 'config.json' file under a '.azure' folder..."
if (!(Test-Path $azureEnvironmentsConfigurationFilePath)) {
    Write-Host "No 'config.json' file found under a '.azure' folder. Please configure an environment..." -ForegroundColor Blue
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

$response = Read-Host "Do you want to use the above environment? (Y/n)"

if ([string]::IsNullOrWhiteSpace($response)) {
    $response = "Y"
}

if (!($response.ToLower() -eq "y")) {
    Write-Host "Use the 'azd env select' command to set the default environment you'd like to use and re-run this script." -ForegroundColor Yellow
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
            $azureDefaultEnvironmentSubscriptionId = $azureDefaultEnvironmentDetailSplitted[1].replace("""", "")
        }
    }
} catch {
    Write-Error -Message "Error getting the default environment details from '.env' file under the default environment configuration folder" -ErrorAction Stop
}

#endregion Get default environment details

#region Validate the Azure subscription configured on the default environment

# Validate the account to use for the configuration of the considered Azure subscription
Write-Host "Account considered for the configuration of the considered Azure subscription: $azureSignedInUserMail" -ForegroundColor Blue
$response = Read-Host "Do you want to use this account for this operation? (Y/n)"

if ([string]::IsNullOrWhiteSpace($response)) {
    $response = "Y"
}

if (!($response.ToLower() -eq "y")) {
    Write-Host "Connection to Azure CLI with the account you want to use for this operation..."
    $azureCliLoginResult = az login --use-device-code
    
    try {
        $azureSignedInUser = az ad signed-in-user show --query '[id, mail]' --output tsv
        $azureSignedInUserMail = $azureSignedInUser[1]
    } catch {
        Write-Error -Message "Error while trying to get the email of the user connected to Azure CLI." -ErrorAction Stop
    }
}

# Get the name of the Azure subscription configured for the default environment
$azureDefaultEnvironmentSubscriptionDisplayName = az account subscription show --id $azureDefaultEnvironmentSubscriptionId --query 'displayName' --output tsv

if (!$?) {
    az account subscription show --id $azureDefaultEnvironmentSubscriptionId --query 'displayName' --output tsv
    Write-Error -Message "Error while trying to get the name of the Azure subscription with the following ID: $azureDefaultEnvironmentSubscriptionId" -ErrorAction Stop
}

Write-Host "Default environment Azure subscription ID: '$azureDefaultEnvironmentSubscriptionDisplayName' ($azureDefaultEnvironmentSubscriptionId)" -ForegroundColor Blue

$response = Read-Host "Do you want to use the above Azure subscription? (Y/n)"

if ([string]::IsNullOrWhiteSpace($response)) {
    $response = "Y"
}

if (!($response.ToLower() -eq "y")) {
    Write-Host "Use the 'azd env set' command to set the Azure subscription you'd like to use with the default environment and re-run this script." -ForegroundColor Yellow
    Exit
}

#endregion Validate the Azure subscription configured on the default environment

#region Create a service principal to manage the solution deployment to the considered Azure subscription

# Check if an app registration with the same name exists, if not create one
$azureDeploymentAppRegistrationName = "sp-$azureDefaultEnvironmentName-azure"

Write-Verbose "Checking if an '$azureDeploymentAppRegistrationName' app registration already exist..."
$azureDeploymentAppRegistrationListResult = az ad app list --filter "displayName eq '$azureDeploymentAppRegistrationName'" --query '[].{id:id, appId:appId}' --output tsv

if (!$?) {
    az ad app list --filter "displayName eq '$azureDeploymentAppRegistrationName'" --query '[].{id:id, appId:appId}' --output tsv
    Write-Error -Message "Error while trying to check if an app registration with the following name already exists: $azureDeploymentAppRegistrationName" -ErrorAction Stop
}

if ([string]::IsNullOrEmpty($azureDeploymentAppRegistrationListResult)) {
    Write-Verbose "No '$azureDeploymentAppRegistrationName' app registration found. Creating app registration..."
    $azureDeploymentAppRegistrationCreationResult = az ad app create --display-name $azureDeploymentAppRegistrationName --query '[id, appId]' --output tsv

    if (!$?) {
        az ad app create --display-name $azureDeploymentAppRegistrationName --query '[id, appId]' --output tsv
        Write-Error -Message "Error while trying to create the following app registration: $azureDeploymentAppRegistrationName" -ErrorAction Stop
    }

    $azureDeploymentAppRegistrationId = $azureDeploymentAppRegistrationCreationResult[1]
    Write-Verbose "👍🏼 '$azureDeploymentAppRegistrationName' app registration created!"
} else {
    $azureDeploymentAppRegistrationId = $azureDeploymentAppRegistrationListResult[1]
    Write-Verbose "Existing '$azureDeploymentAppRegistrationName' app registration found."
}

# Check if a service principal with the same name exists, if not create one
Write-Verbose "Checking if a '$azureDeploymentAppRegistrationName' service principal already exist..."
$azureDeploymentServicePrincipalId = az ad sp list --filter "appId eq '$azureDeploymentAppRegistrationId'" --query [].id --output tsv

if (!$?) {
    az ad sp list --filter "appId eq '$azureDeploymentAppRegistrationId'" --query [].id --output tsv
    Write-Error -Message "Error while trying to check if a service principal exists for the following app registration: $azureDeploymentAppRegistrationName" -ErrorAction Stop
}

if ([string]::IsNullOrEmpty($azureDeploymentServicePrincipalId)) {
    Write-Verbose "No '$azureDeploymentAppRegistrationName' service principal found. Creating service principal..."
    $azureDeploymentServicePrincipalId = az ad sp create --id $azureDeploymentAppRegistrationId --query id --output tsv

    if (!$?) {
        az ad sp create --id $azureDeploymentAppRegistrationId --query id --output tsv
        Write-Error -Message "Error while trying to create a service principal for the following app registration: $azureDeploymentAppRegistrationName" -ErrorAction Stop
    }

    Write-Verbose "👍🏼 '$azureDeploymentAppRegistrationName' service principal created!"
} else {
    Write-Verbose "Existing '$azureDeploymentAppRegistrationName' service principal found."
}

# Create role assignments for the service principal on the considered Azure subscription
Write-Verbose "Role assignments creation for the '$azureDeploymentAppRegistrationName' service principal on the '$azureDefaultEnvironmentSubscriptionDisplayName' Azure subscription..."
foreach ($roleToAssignOnAzureSubscription in $rolesToAssignOnAzureSubscription) {
    Write-Verbose "Creation of an assignment for the role '$roleToAssignOnAzureSubscription'..."
    $roleAssignmentCreationResult = az role assignment create --subscription $azureDefaultEnvironmentSubscriptionId --role $roleToAssignOnAzureSubscription --assignee-object-id $azureDeploymentServicePrincipalId --assignee-principal-type ServicePrincipal

    if (!$?) {
        az role assignment create --subscription $azureDefaultEnvironmentSubscriptionId --role $roleToAssignOnAzureSubscription --assignee-object-id $azureDeploymentServicePrincipalId --assignee-principal-type ServicePrincipal
        Write-Error -Message "Error while trying to assign the '$roleToAssignOnAzureSubscription' role to the '$azureDeploymentAppRegistrationName' service principal on the '$azureDefaultEnvironmentSubscriptionDisplayName' Azure subscription." -ErrorAction Stop
    }

    Write-Verbose "👍🏼 '$roleToAssignOnAzureSubscription' role has been assigned!"
}

# Add service principal name as an environment variable to the default environment
Write-Verbose "Add service principal name to the '.env' file of the default environment..."
azd env set AZURE_SERVICE_PRINCIPAL_NAME $azureDeploymentAppRegistrationName

if (!$?) {
    Write-Error -Message "Error while trying to set the value of the 'AZURE_SERVICE_PRINCIPAL_NAME' environment variable to '$azureDeploymentAppRegistrationName'." -ErrorAction Stop
}

Write-Verbose "👍🏼 Service principal name added to the '.env' file of the default environment!"

#endregion Create a service principal to manage the solution deployment to the considered Azure subscription

#region Create a service principal to be assigned as an application user to the considered Dataverse environment

# Validate the account to use for the creation of the service principal to manage the integration with the Dataverse environment
Write-Host "Account considered for creation of the service principal to manage the integration with the Dataverse environment: $azureSignedInUserMail" -ForegroundColor Blue
$response = Read-Host "Do you want to use this account for this operation? (Y/n)"

if ([string]::IsNullOrWhiteSpace($response)) {
    $response = "Y"
}

if (!($response.ToLower() -eq "y")) {
    Write-Host "Connection to Azure CLI with the account you want to use for this operation..."
    $azureCliLoginResult = az login --use-device-code --allow-no-subscriptions
    
    try {
        $azureSignedInUser = az ad signed-in-user show --query '[id, mail]' --output tsv
        $azureSignedInUserMail = $azureSignedInUser[1]
    } catch {
        Write-Error -Message "Error while trying to get the email of the user connected to Azure CLI." -ErrorAction Stop
    }
}

# Check if an app registration with the same name exists, if not create one
$dataverseAppRegistrationName = "sp-$azureDefaultEnvironmentName-dataverse"

Write-Verbose "Checking if an '$dataverseAppRegistrationName' app registration already exist..."
$dataverseAppRegistrationListResult = az ad app list --filter "displayName eq '$dataverseAppRegistrationName'" --query '[].{id:id, appId:appId}' --output tsv

if (!$?) {
    az ad app list --filter "displayName eq '$dataverseAppRegistrationName'" --query '[].{id:id, appId:appId}' --output tsv
    Write-Error -Message "Error while trying to check if an app registration with the following name already exists: $dataverseAppRegistrationName" -ErrorAction Stop
}

if ([string]::IsNullOrEmpty($dataverseAppRegistrationListResult)) {
    Write-Verbose "No '$dataverseAppRegistrationName' app registration found. Creating app registration..."
    $dataverseAppRegistrationCreationResult = az ad app create --display-name $dataverseAppRegistrationName --query '[id, appId]' --output tsv

    if (!$?) {
        az ad app create --display-name $dataverseAppRegistrationName --query '[id, appId]' --output tsv
        Write-Error -Message "Error while trying to create the following app registration: $dataverseAppRegistrationName" -ErrorAction Stop
    }

    $dataverseAppRegistrationId = $dataverseAppRegistrationCreationResult[1]
    Write-Verbose "👍🏼 '$dataverseAppRegistrationName' app registration created!"
} else {
    $dataverseAppRegistrationId = $dataverseAppRegistrationListResult[1]
    Write-Verbose "Existing '$dataverseAppRegistrationName' app registration found."
}

# Check if a service principal with the same name exists, if not create one
Write-Verbose "Checking if a '$dataverseAppRegistrationName' service principal already exist..."
$dataverseServicePrincipalId = az ad sp list --filter "appId eq '$dataverseAppRegistrationId'" --query [].id --output tsv

if (!$?) {
    az ad sp list --filter "appId eq '$dataverseAppRegistrationId'" --query [].id --output tsv
    Write-Error -Message "Error while trying to check if a service principal exists for the following app registration: $dataverseAppRegistrationName" -ErrorAction Stop
}

if ([string]::IsNullOrEmpty($dataverseServicePrincipalId)) {
    Write-Verbose "No '$dataverseAppRegistrationName' service principal found. Creating service principal..."
    $dataverseServicePrincipalId = az ad sp create --id $dataverseAppRegistrationId --query id --output tsv

    if (!$?) {
        az ad sp create --id $dataverseAppRegistrationId --query id --output tsv
        Write-Error -Message "Error while trying to create a service principal for the following app registration: $dataverseAppRegistrationName" -ErrorAction Stop
    }

    Write-Verbose "👍🏼 '$dataverseAppRegistrationName' service principal created!"
} else {
    Write-Verbose "Existing '$dataverseAppRegistrationName' service principal found."
}

# Reset credential on service principal
Write-Verbose "Reset credential on the '$dataverseAppRegistrationName' service principal..."
$dataverseServicePrincipalCredentialResetResult = az ad sp credential reset --id $dataverseAppRegistrationId --display-name "azd - dataverse - $azureDefaultEnvironmentName" | ConvertFrom-Json

if (!$?) {
    az ad sp credential reset --id $dataverseAppRegistrationId --display-name "azd - dataverse - $azureDefaultEnvironmentName"
    Write-Error -Message "Error while trying to reset credential on the following service principal: $dataverseAppRegistrationName" -ErrorAction Stop
}

$dataverseServicePrincipalPassword = $dataverseServicePrincipalCredentialResetResult.password

if (![string]::IsNullOrEmpty($dataverseServicePrincipalPassword)) {
    Write-Verbose "👍🏼 Credendial reset for the '$dataverseAppRegistrationName' service principal completed!"
} else {
    Write-Error -Message "Error during credendial reset for the '$dataverseAppRegistrationName' service principal." -ErrorAction Stop
}

# Add application registration name as an environment variable to the default environment
Write-Verbose "Add application registration name to the '.env' file of the default environment..."
azd env set DATAVERSE_SERVICE_PRINCIPAL_NAME $dataverseAppRegistrationName

if (!$?) {
    Write-Error -Message "Error while trying to set the value of the 'DATAVERSE_SERVICE_PRINCIPAL_NAME' environment variable to '$dataverseAppRegistrationName'." -ErrorAction Stop
}

Write-Verbose "👍🏼 Application registration name added to the '.env' file of the default environment!"

# Add application registration id as an environment variable to the default environment
Write-Verbose "Add application registration id to the '.env' file of the default environment..."
azd env set DATAVERSE_CLIENT_ID $dataverseAppRegistrationId

if (!$?) {
    Write-Error -Message "Error while trying to set the value of the 'DATAVERSE_CLIENT_ID' environment variable to '$dataverseAppRegistrationId'." -ErrorAction Stop
}

Write-Verbose "👍🏼 Application registration id added to the '.env' file of the default environment!"

# Add service principal password as an environment variable to the default environment
Write-Verbose "Add service principal password to the '.env' file of the default environment..."
azd env set DATAVERSE_CLIENT_SECRET $dataverseServicePrincipalPassword

if (!$?) {
    Write-Error -Message "Error while trying to set the value of the 'DATAVERSE_CLIENT_SECRET' environment variable to '$dataverseServicePrincipalPassword'." -ErrorAction Stop
}

Write-Verbose "👍🏼 Service principal password added to the '.env' file of the default environment!"

#endregion Create a service principal to be assigned as an application user to the considered Dataverse environment

#region Get Dataverse environment URL

$dataverseEnvironmentUrl = ""

# Ask for the URL of the Dataverse environment to consider
$response = Read-Host "Please, enter the URL of the Dataverse environment to consider or just press enter so an environment can be created"

if ([string]::IsNullOrEmpty($response)) {
    # Test the path provided to the file with the configurations
    Write-Verbose "Test the path provided to the file with the configuration: $dataverseEnvironmentConfigurationFilePath"
    if (!(Test-Path $dataverseEnvironmentConfigurationFilePath)) {
        Write-Error -Message "Following path to configuration file not valid: $dataverseEnvironmentConfigurationFilePath" -ErrorAction Stop
    }
    
    # Extract configuration from the file
    Write-Verbose "Get content from file with the configurations in the following location: $dataverseEnvironmentConfigurationFilePath"
    try {
        $dataverseEnvironmentConfiguration = Get-Content $dataverseEnvironmentConfigurationFilePath -ErrorVariable getConfigurationError -ErrorAction Stop | ConvertFrom-Json
    }
    catch {
        Write-Error -Message "Error in the extraction of the configuration from the considered file ($dataverseEnvironmentConfigurationFilePath): $getConfigurationError" -ErrorAction Stop
    }

    $dataverseEnvironmentConfiguration

    $response = Read-Host "Are you OK with this configuration? (Y/n)"

    if ([string]::IsNullOrWhiteSpace($response)) {
        $response = "Y"
    }

    if (!($response.ToLower() -eq "y")) {
        Write-Host "Please review and update the configuration in the following file: $dataverseEnvironmentConfigurationFilePath" -ForegroundColor Yellow
        Exit
    } else {
        $dataverseEnvironmentName = $dataverseEnvironmentConfiguration.namePrefix + $azureDefaultEnvironmentName
        $dataverseEnvironmentDomain = $dataverseEnvironmentConfiguration.domainPrefix + $azureDefaultEnvironmentName.ToLower()
        Write-Verbose "Create '$dataverseEnvironmentName' ($dataverseEnvironmentDomain) Dataverse environment..."
        
        $dataverseEnvironmentType = $dataverseEnvironmentConfiguration.type
        $dataverseEnvironmentRegion = $dataverseEnvironmentConfiguration.region
        $dataverseEnvironmentLanguage = $dataverseEnvironmentConfiguration.language
        $dataverseEnvironmentCurrency = $dataverseEnvironmentConfiguration.currency
        
        $dataverseEnvironmentCreationResult = pac admin create --name "$dataverseEnvironmentName" --domain "$dataverseEnvironmentDomain" --type "$dataverseEnvironmentType" --region "$dataverseEnvironmentRegion" --language "$dataverseEnvironmentLanguage" --currency "$dataverseEnvironmentCurrency"

        if (!$?) {
            pac admin create --name "$dataverseEnvironmentName" --domain "$dataverseEnvironmentDomain" --type "$dataverseEnvironmentType" --region "$dataverseEnvironmentRegion" --language "$dataverseEnvironmentLanguage" --currency "$dataverseEnvironmentCurrency"
            Write-Error -Message "Error while trying to create the following Power Platform environment: $dataverseEnvironmentName ($dataverseEnvironmentDomain)" -ErrorAction Stop
        }

        $dataverseEnvironmentCreationResultLineWithUrlSplitted = $dataverseEnvironmentCreationResult[5].split(" ")
        $dataverseEnvironmentUrl = $dataverseEnvironmentCreationResultLineWithUrlSplitted[0]
    }
} else {
    $dataverseEnvironmentUrl = $response
}

# Add Dataverse environment URL as an environment variable to the default environment
Write-Verbose "Add Dataverse environment URL to the '.env' file of the default environment..."
azd env set DATAVERSE_ENV_URL $dataverseEnvironmentUrl

if (!$?) {
    Write-Error -Message "Error while trying to set the value of the 'DATAVERSE_ENV_URL' environment variable to '$dataverseEnvironmentUrl'." -ErrorAction Stop
}

Write-Verbose "👍🏼 Dataverse environment URL added to the '.env' file of the default environment!"

#endregion Get Dataverse environment URL

#region Assign app registration as an application user to the considered Dataverse environment

Write-Verbose "Assign '$dataverseAppRegistrationName' app registration to '$dataverseEnvironmentUrl' Dataverse environment"
$appUserAssignmentResult = pac admin assign-user --environment "$dataverseEnvironmentUrl" --user "$dataverseAppRegistrationId" --role "$dataverseSecurityRoleNameForApplicationUser" --application-user --async

if (!$?) {
    pac admin assign-user --environment "$dataverseEnvironmentUrl" --user "$dataverseAppRegistrationId" --role "$dataverseSecurityRoleNameForApplicationUser" --application-user --async
    Write-Error -Message "Error while trying to assign the '$dataverseAppRegistrationName' service principal as '$dataverseSecurityRoleNameForApplicationUser' in the following Power Platform environment: $dataverseEnvironmentUrl" -ErrorAction Stop
}

Write-Verbose "👍🏼 App registration assigned to Dataverse environment!"

#endregion Assign app registration as an application user to the considered Dataverse environment