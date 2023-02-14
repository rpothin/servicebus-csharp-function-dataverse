<p align="center">
    <h1 align="center">
        Prerequisites for deploying the solution
    </h1>
</p>

## Tools

> **Note**
> If you plan to use a devcontainer definiton, like for [GitHub Codespaces](https://github.com/features/codespaces), the one included in this repository contains all the things you will need to start working with this template.

The following prerequisites are required to use this solution. Please ensure that you checked all these points before starting.

- [Git](https://git-scm.com/)
- [GitHub CLI (v2.3+)](https://github.com/cli/cli)
- [Azure CLI (2.38.0+)](https://docs.microsoft.com/cli/azure/install-azure-cli)
- [Azure Developer CLI](https://aka.ms/azure-dev/install)

```powershell
# For Windows
powershell -ex AllSigned -c "Invoke-RestMethod 'https://aka.ms/install-azd.ps1' | Invoke-Expression"

# For Linux/MacOS
curl -fsSL https://aka.ms/install-azd.sh | bash
```

- [.NET SDK 6.0](https://dotnet.microsoft.com/download/dotnet/6.0) - _for the Azure Functions application code_
- [Power Platform CLI](https://learn.microsoft.com/en-us/power-platform/developer/cli/introduction#install-microsoft-power-platform-cli) - _for the configuration of the Power Platform environment throught the execution of the [post-init-setup](./scripts/post-init-setup.ps1) PowerShell script_

> **Note**
> The configuration of the Azure and Power Platform parts can be done with 2 different accounts in 2 different tenants.

## Azure

An account with:
- access to an active Azure subscription (_you can [create one for free](https://azure.microsoft.com/free/?WT.mc_id=A261C142F) if you don't have one yet_)
- the permission to create an application registration in Azure AD (*for the management of the Azure deployment from GitHub*)

> **Note**
> To be able to configure the solution you will need at least the roles below on the considered Azure subscription:
> - [Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#contributor)
> - [User Access Administrator](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#user-access-administrator) - _for the configuration of the access of the Azure Functions application to the Azure Service Bus_

## Power Platform

An account with:
- access to an existing Power Platform environment as a `System Administrator` **or** the permission to create a new Power Platform environment
- the permission to create an application registration in Azure AD (*for the communication from the Azure Functions application to the Power Platform environment*)

> **Note**
> To explore the Power Platform part of this template you can use one of the following free ways:
> - [Power Apps Developer Plan](https://learn.microsoft.com/en-us/power-apps/maker/developer-plan)
> - [Microsoft 365 Developer Program](https://developer.microsoft.com/en-us/microsoft-365/dev-program)
> - [Dynamics 365 Free Trial](https://dynamics.microsoft.com/en-us/dynamics-365-free-trial/)