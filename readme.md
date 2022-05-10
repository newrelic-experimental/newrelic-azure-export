[![New Relic Experimental header](https://github.com/newrelic/opensource-website/raw/master/src/images/categories/Experimental.png)](https://opensource.newrelic.com/oss-category/#new-relic-experimental)

# Azure Function to Pull New Relic Data into Log Analytics  
This function will make a query to NRDB via nerdgraph API on a set interval (5 minutes by default) and will pull data for the previous requested minutes (again by default set to 5 minutes)


## Requirements:
1. you need a userkey to query data from New Relic ([see docs](https://docs.newrelic.com/docs/apis/intro-apis/new-relic-api-keys/))  
2. A Log Analytics Workspace already setup.
3. Grab these details from your Log Analytics Workspace
    *  Workspace ID
    *  Primary Key

4. NRQL Query.


## Setup:
Most of the information above will live in the ``config.json`` file. In the future this should be updated so these details can be added via the azure functions ui. 

```
{
    "key": "<<REPLACE WITH AZURE LA PRIMARY KEY>>",
    "CustomerId": "<<REPLACE WITH AZURE LA WORKSPACE ID>>",
    "NRQL": "<<REPLACE WITH YOUR NRQL QUERY FOR EXAMPLE: From SystemSample Select * >>",
    "LogType": "<<REPLACE WITH YOUR NAME TABLE NAME>>",
    "MinutesInterval": "5",
    "NRKey": "<<REPLACE WITH NR USER KEY>>"
}
```


### Function Setup:
There isn't a whole lot special here. This is a powershell based function so if you want to create it via the UI instead of pushing from your local machine, then make sure to create the function app for powershell core & windows. The Trigger should be set to time and it is HIGHLY recommended to match your time with **MinutesInterval** in the ``config.json``. This means that if you set your timer trigger to every 10 minutes then **MinutesInterval** should be set to 10. 



## To do:
- [ ] Move Config File use to App settings in Azure
- [ ] Add proper Error handling
- [ ] Test to make sure all data is pulled without any gaps.
- [ ] Maybe instead of using ``since x minutes ago`` it would be better to use the timestamp of the last event previously pulled? not sure how to do that quite yet. 


License
NewRelic Azure Export is licensed under the Apache 2.0 License.

