<p align="center">
    <h1 align="center">
        Test the deployed solution
    </h1>
</p>

[![Watch test demonstration](https://i3.ytimg.com/vi/FkhUpgTQiUY/maxresdefault.jpg)](https://youtu.be/FkhUpgTQiUY)

To test the solution, you can manually push a message in the `dataverse-inbound` queue (_configured in the [**main.parameters.json**](../infra/main.parameters.json) file_) - for example, you can do it directly from the queue in Azure Portal using the [**Service Bus Explorer**](https://learn.microsoft.com/en-us/azure/service-bus-messaging/explorer) feature.

![image](https://user-images.githubusercontent.com/23240245/206925350-67e9676f-9048-4fe3-9d91-56c581e3e498.png)

![image](https://user-images.githubusercontent.com/23240245/206925370-1fd3710d-8768-4b59-8948-d33c18c1518f.png)

![image](https://user-images.githubusercontent.com/23240245/206925390-f41c234e-0b5b-4e9c-b784-671059d43c80.png)

![image](https://user-images.githubusercontent.com/23240245/206925407-0eb0fcf2-4396-4ba9-92c4-c5382061b35f.png)

To validate the consumption of the message you can:

- open the Azure Functions resource, go to the **ProcessServiceBusMessage** function and check the runs in the **Monitor** section

![image](https://user-images.githubusercontent.com/23240245/206925451-9941f3df-6485-443a-ae41-39fb662a87e1.png)

![image](https://user-images.githubusercontent.com/23240245/206925464-635b1be1-f476-42e0-ac32-2b034523e073.png)

- open the Application Insights resource, go to the **Transaction Search**

![image](https://user-images.githubusercontent.com/23240245/206925683-c1a78466-182d-496d-8b1a-01b3cd55e29c.png)

In both places above you should see the traces below:

- `C# ServiceBus queue trigger function processed message`
- `Logged on user id`

![image](https://user-images.githubusercontent.com/23240245/206925481-dbff2ad3-17f6-4ff6-b852-b2da97f005cc.png)

If you find the documented traces it means the solution provided in this template is working as expected.

---

### [🏡 README - Documentation](../README.md#-documentation)