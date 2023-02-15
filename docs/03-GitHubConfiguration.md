<p align="center">
    <h1 align="center">
        GitHub configuration
    </h1>
</p>

Follow the steps below to configure the elements required to run the GitHub workflow to provision the Azure resources and deploy the Azure Functions application code.

> **Note**
> The GitHub workflow proposed in this template is configured to automatically trigger only if the `azure.yaml` file or the files under the following folders are updated: `infra` or `src`

## Configuration of secrets for custom environment variables

Set the GitHub actions secrets associated to the [custom environment variables](./A2-CustomEnvironmentVariables.md) using the command below:

```powershell
# Paste secret value for the current repository in an interactive prompt
gh secret set <secret name>
```

| **Secret Name**         | **Description**                                                                                                                                                                                                                                                                                                                            |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| DATAVERSE_ENV_URL       | URL of the considered Dataverse / Power Platform environment configured in the Key Vault during Azure infrastructure deployment for the communication from the Azure Functions application to the Power Platform / Dataverse environment                                                                                                   |
| DATAVERSE_CLIENT_ID     | Client ID of the Azure AD application registration configured as an application user with permissions in the considered Dataverse / Power Platform environment configured in the Key Vault during Azure infrastructure deployment for the communication from the Azure Functions application to the Power Platform / Dataverse environment |
| DATAVERSE_CLIENT_SECRET | Secret of the Azure AD application registration configured as an application user with permissions in the considered Dataverse / Power Platform environment configured in the Key Vault during Azure infrastructure deployment for the communication from the Azure Functions application to the Power Platform / Dataverse environment    |

> **Note**
> If you are in GitHub Codespaces you could get an error like the following one: `Error: failed setting AZURE_CREDENTIALS secret: failed running gh secret set exit code: 1, stdout: , stderr: failed to fetch public key: HTTP 403: Resource not accessible by integration (https://api.github.com/repos/savannahostrowski/codespaces-test/actions/secrets/public-key)
: exit status 1`
> As a workaround, you can run the following commands in the Terminal:
> - `export GITHUB_TOKEN=` to unset GITHUB_TOKEN
> - `gh auth login` to log in to GitHub CLI (by default repo scope is included)

## Finalize GitHub configuration

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

---

### [🏡 README - Documentation](../README.md#-documentation)