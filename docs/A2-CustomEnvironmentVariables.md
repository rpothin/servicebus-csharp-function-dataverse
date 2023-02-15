<p align="center">
    <h1 align="center">
        Custom environment variables
    </h1>
</p>

> **Note**
> You will be able to find this values in the `.env` files under `.azure`.

| **Key**                          | **Description**                                                                                                                                                                                                                                                                                                                            |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| DATAVERSE_ENV_URL                | URL of the considered Dataverse / Power Platform environment configured in the Key Vault during Azure infrastructure deployment for the communication from the Azure Functions application to the Power Platform / Dataverse environment                                                                                                   |
| DATAVERSE_CLIENT_ID              | Client ID of the Azure AD application registration configured as an application user with permissions in the considered Dataverse / Power Platform environment configured in the Key Vault during Azure infrastructure deployment for the communication from the Azure Functions application to the Power Platform / Dataverse environment |
| DATAVERSE_CLIENT_SECRET          | Secret of the Azure AD application registration configured as an application user with permissions in the considered Dataverse / Power Platform environment configured in the Key Vault during Azure infrastructure deployment for the communication from the Azure Functions application to the Power Platform / Dataverse environment    |
| AZURE_SERVICE_PRINCIPAL_NAME     | Name of the application registration / service principal to manage Azure deployment from GitHub                                                                                                                                                                                                                                            |
| DATAVERSE_SERVICE_PRINCIPAL_NAME | Name of the application registration / service principal to manage the communication from the Azure Functions application to the Power Platform / Dataverse environment                                                                                                                                                                    |

---

### [🏡 README - Documentation](../README.md#-documentation)