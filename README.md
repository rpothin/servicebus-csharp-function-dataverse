<p align="center">
    <h1 align="center">
        Azure Developer CLI Template - rpothin/servicebus-csharp-function-dataverse
    </h1>
    <h3 align="center">
        Application to process messages from an Azure Service Bus to a Dataverse environment through a C# Azure Functions application using the Microsoft.PowerPlatform.Dataverse.Client package.
    </h3>
</p>

<p align="center">
    <a href="https://github.com/rpothin/servicebus-csharp-function-dataverse/blob/main/LICENSE" alt="Repository License">
        <img src="https://img.shields.io/github/license/rpothin/servicebus-csharp-function-dataverse?color=yellow&label=License" /></a>
    <a href="https://github.com/rpothin/servicebus-csharp-function-dataverse/issues" alt="Open Issues">
        <img src="https://img.shields.io/github/issues-raw/rpothin/servicebus-csharp-function-dataverse?label=Open%20Issues" /></a>
    <a href="https://github.com/rpothin/servicebus-csharp-function-dataverse/pulls" alt="Open Pull Requests">
        <img src="https://img.shields.io/github/issues-pr-raw/rpothin/servicebus-csharp-function-dataverse?label=Open%20Pull%20Requests" /></a>
</p>

<p align="center">
    <a href="#watchers" alt="Watchers">
        <img src="https://img.shields.io/github/watchers/rpothin/servicebus-csharp-function-dataverse?style=social" /></a>
    <a href="#forks" alt="Forks">
        <img src="https://img.shields.io/github/forks/rpothin/servicebus-csharp-function-dataverse?style=social" /></a>
    <a href="#stars" alt="Stars">
        <img src="https://img.shields.io/github/stars/rpothin/servicebus-csharp-function-dataverse?style=social" /></a>
</p>

<h3 align="center">
  <a href="https://github.com/rpothin/servicebus-csharp-function-dataverse/discussions?discussions_q=category%3AIdeas">Feature request</a>
  <span> · </span>
  <a href="https://github.com/rpothin/servicebus-csharp-function-dataverse/issues/new?assignees=rpothin&labels=bug%2Ctriage&template=BUG.yml&title=%5BBug%5D+%3CTitle%3E">Report a bug</a>
  <span> · </span>
  <a href="https://github.com/rpothin/servicebus-csharp-function-dataverse/discussions/categories/q-a">Support Q&A</a>
</h3>

## 📢 What is the servicebus-csharp-function-dataverse project?

It is a GitHub repository using the [**Azure Developer CLI**](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/overview) to get you up and running on Azure quickly in a scenario where you need to process messages from an Azure Service Bus to a Dataverse environment through a C# Azure Functions app.

It contains components (infrastructure as code in Bicep, C# Azure Functions application code...) that will help you be up and running quickly.

## 📖 Documentation

1. [Prerequisites for deploying the solution](./docs/00-Prerequisites.md)
2. [Setup and deployment of the solution](./docs/01-Quickstart.md)
3. [Test the deployed solution](./docs/02-TestTheSolution.md)

### Annex

- [Custom environment variables](./docs/A2-CustomEnvironmentVariables.md)

### GitHub configuration

Follow the steps below to configure the elements required to run the GitHub workflow to provision the Azure resources and deploy the Azure Functions application code.

> **Note**
> The considered service principal will need to have the following permissions ont the considered Azure subscription:
> - [Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#contributor)
> - [User Access Administrator](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#user-access-administrator) - _for the configuration of the access of the Azure Functions application to the Azure Service Bus_

> **Note**
> If you ran the [**post-init-setup**](./scripts/post-init-setup.ps1) PowerShell script, you can considered the value of the `AZURE_SERVICE_PRINCIPAL_NAME` environment variable.

In your workspace linked to a GitHub repository execute the command below:

```powershell
azd pipeline config --auth-type federated --principal-name <service principal name>
```

> **Note**
> If you are in GitHub Codespaces you get an error like the following one: `Error: failed setting AZURE_CREDENTIALS secret: failed running gh secret set exit code: 1, stdout: , stderr: failed to fetch public key: HTTP 403: Resource not accessible by integration (https://api.github.com/repos/savannahostrowski/codespaces-test/actions/secrets/public-key)
: exit status 1`
> As a workaround, you can run the following commands in the Terminal:
> - `export GITHUB_TOKEN=` to unset GITHUB_TOKEN
> - `gh auth login` to log in to GitHub CLI (by default repo scope is included)

Set the actions secrets associated to the custom environment variables using the command below

```powershell
# Paste secret value for the current repository in an interactive prompt
gh secret set <secret name>
```

| **Secret Name**         | **Description**                                                                                                                                                                                                                                                                                                                            |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| DATAVERSE_ENV_URL       | URL of the considered Dataverse / Power Platform environment configured in the Key Vault during Azure infrastructure deployment for the communication from the Azure Functions application to the Power Platform / Dataverse environment                                                                                                   |
| DATAVERSE_CLIENT_ID     | Client ID of the Azure AD application registration configured as an application user with permissions in the considered Dataverse / Power Platform environment configured in the Key Vault during Azure infrastructure deployment for the communication from the Azure Functions application to the Power Platform / Dataverse environment |
| DATAVERSE_CLIENT_SECRET | Secret of the Azure AD application registration configured as an application user with permissions in the considered Dataverse / Power Platform environment configured in the Key Vault during Azure infrastructure deployment for the communication from the Azure Functions application to the Power Platform / Dataverse environment    |

### Architecture

![servicebus-csharp-function-dataverse](https://user-images.githubusercontent.com/23240245/194187578-dd13f3d7-22bb-486e-a54c-1a8242cc5e7a.jpg)

```mermaid
graph TB
    subgraph Function Apps
        sbTrigger
    end

    subgraph Service Bus
        sb(Queue)
        sb-->|On message add|sbTrigger(Queue Trigger)
    end

    subgraph Azure Monitor
        ai(application Insights)
        la(Log Analytics workspace)
        sbTrigger-->|Message and logged in user id|ai
        ai-->la
    end

    subgraph Power Platform
        dataverse(Dataverse)
        sbTrigger-->|Get logged in user details|dataverse
    end

```

## ❗ Code of Conduct

I, **Raphael Pothin** ([@rpothin](https://github.com/rpothin)), as creator of this project, am dedicated to providing a welcoming, diverse, and harrassment-free experience for everyone.
I expect everyone visiting or participating in this project to abide by the following [**Code of Conduct**](CODE_OF_CONDUCT.md).
Please read it.

## 👐 Contributing to this project

From opening a bug report to creating a pull request: every contribution is appreciated and welcomed.
For more information, see [CONTRIBUTING.md](CONTRIBUTING.md)

### Not Sure Where to Start?

If you want to participate to this project, but you are not sure how you can do it, do not hesitate to contact [@rpothin](https://github.com/rpothin):

- By email at **raphael.pothin@gmail.com**
- On [Twitter](https://twitter.com/RaphaelPothin)

## 📝 License

All files in this repository are subject to the [MIT](LICENSE) license.

## 💡 Inspiration

We would like to thank the open-source projects below that helped us find some ideas on how to organize this project.

- [Azure-Samples/todo-csharp-cosmos-sql](https://github.com/Azure-Samples/todo-csharp-cosmos-sql) & all the other [great Azure Developer CLI templates](https://azure.github.io/awesome-azd/)
- [Gordonby/servicebus-dotnet-functionapp](https://github.com/Gordonby/servicebus-dotnet-functionapp)
