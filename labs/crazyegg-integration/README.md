# Crazy Egg Integration

The Crazy Egg integration allows you to see heatmaps with Optimizely data.

## Pre-requisites

* You'll need a Crazy Egg account. Head here to get started: [https://www.crazyegg.com](https://www.crazyegg.com).
* You'll need an Optimizely Web project with at least one experiment set up.
* The [force variation parameter](https://help.optimizely.com/QA_Campaigns_and_Experiments/Force_behaviors_in_Optimizely_X_using_query_parameters) needs to be enabled. It can be enabled by going to the Settings tab in Optimizely, then make sure the "Disable force variation parameter" box is unchecked.

## Optimizely Setup

1. Navigate to the Optimizely project in which you want to use the integration.
2. Click on **Settings** in the left navigation bar, and then **Integrations**.
3. Click on the blue button titled **"Create New Analytics Integration"**.
4. In the dropdown menu select **Using JSON**.
5. Copy and paste the following code into the _JSON Code_ window in Optimizely and click **Create Integration**.

```
{
  "plugin_type": "analytics_integration",
  "name": "Crazy Egg",
  "form_schema": [
    {
      "default_value": "off",
      "field_type": "dropdown",
      "name": "heatmaps",
      "label": "Heatmaps",
      "options": {
        "choices": [
          {
            "value": "off",
            "label": "Off"
          },
          {
            "value": "on",
            "label": "On"
          }
        ]
      }
    }
  ],
  "description": "This integration allows you to see heatmaps with Optimizely data.
  "options": {
    "track_layer_decision": "if(extension.heatmaps === \"on\") {\n  if(!isHoldback) {\n    window.CE_SNAPSHOT_NAME = '' + variationId;\n  }\n}\n"
  }
}
```
6. Select **Crazy Egg** in the integration list and **enable** the integration.
7. Click on **Experiments** in the left navigation bar, click on the **Name** of the experiment.
8. Click on **Integrations** in the submenu, and make sure the Crazy Egg Heatmaps field is **On**.
9. Next you will need to find your experiment's variation IDs. Click on **API Names** in the submenu.
10. Find the **variation ID's** for the control and any variants, you will need these for the Crazy Egg setup.

## Crazy Egg Setup

In Crazy Egg, you will need to create a separate snapshot for each ID. 
1. The **Snapshot URL** will need to have the experiment page URL appended with `optimizely_x` query param. Example: https://www.example.com/my-page/?optimizely_x=VARIATIONID.
2. The **Snapshot name** will need to be the **variant ID**
3. Under the **Advanced settings**, select the Tracking Option of **Track by name**. Note: You just need to select this option, you won't need to add the additional code on your page since the integration automatically handles it.
