Microsoft Graph and expolore its power

Microsoft Graph is the gateway to data and intelligence in Microsoft 365 platform. Microsoft Graph exposes REST APIs and client libraries across data on the following cloud services:
Microsoft 365 core services
Enterprise Mobility + Security services
Windows services
Dynamics 365 Business Central services

Please explore more in here [Reference] (https://learn.microsoft.com/en-us/graph/overview?view=graph-rest-1.0#whats-in-microsoft-graph "Reference") 

In this post, I would like to focus on how we can configure the Subscription resource and use it for different resources, in order to receive notifications about changes to data in Microsoft Graph.

Accross Graph API you can by using subscription resource you have a chance to create listener. A subscription allows a client app to receive change notifications about changes in Microsoft Graph and it is now supported on different resource types such as an alert from Microsoft Graph Security API, a group in Azure Active Directory and the presence of a user on Microsoft Teams.


![graphPost1](graphPost1.png)