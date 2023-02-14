<p align="center">
    <h1 align="center">
        Setup and deployment of the solution
    </h1>
</p>

[![Watch Quickstart demonstration](https://i3.ytimg.com/vi/rcVtA19GyeU/maxresdefault.jpg)](https://youtu.be/rcVtA19GyeU)

The fastest way for you to get this application up and running on Azure is to follow the procedure below.

> **Note**
> In GitHub there is even a easier way than the one below:
> - From the [rpothin/servicebus-csharp-function-dataverse](https://github.com/rpothin/servicebus-csharp-function-dataverse) GitHub repository, click on the **Use this template** button
> - Select the **Open in a codespace** option
> - Go directly to the step 3 of this section

1. Open a terminal, create a new empty folder, and change into it
2. Run the following command to initialize the project

```powershell
azd init --template rpothin/servicebus-csharp-function-dataverse
```

You will be prompted for the following information:

- `Environment Name`: This will be used in the name of the the resource group and the resources that will be created in Azure. This name should be unique within your Azure subscription.
- `Azure Location`: The Azure location where your resources will be deployed.
- `Azure Subscription`: The Azure Subscription where your resources will be deployed.

3. Run the following command to finalize the initialization of the project

```powershell
# For Windows
.\scripts\post-init-setup.ps1

# For Linux/MacOS
pwsh scripts/post-init-setup.ps1

# You can add the "-verbose" parameter to get more details during the execution
```

> **Note**
> This PowerShell script will:
> - create an application registration in Azure AD for the Azure deployment from GitHub
> - create an application registration in Azure AD for the communication from the Azure Functions application to the Power Platform / Dataverse environment
> - offer to create a Power Platform / Dataverse environment based on the element in the [Dataverse environment configuration](./.dataverse/environment-configuration.json) file
> - register the second application registration created in Azure AD as an application user in the considered Power Platform / Dataverse environment with the `Service Reader` security role

4. Run the following command to provision Azure resources, and deploy the application code

> **Note**
> If you use 2 different accounts for the configuration of the Azure and Power Platform part, you will need to connect again with your "Azure" account before running the following command. You can do that using the `az login --use-device-code` command.

```powershell
azd up
```

> **Note**
> This may take a while to complete as it executes two commands: `azd provision` (provisions Azure resources) and `azd deploy` (deploys application code). You will see a progress indicator as it provisions and deploys your application.

When `azd up` is complete it will output the following URLs:

- Azure Portal link to view resources
- Azure Functions application