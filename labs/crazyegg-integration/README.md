# Crazy Egg Integration

The Crazy Egg integration allows you to see heatmaps with Optimizely data.

## Pre-requisites

* You'll need a Crazy Egg account. Head here to get started: [https://www.crazyegg.com](https://www.crazyegg.com).
* You'll need an Optimizely Web project with at least one experiment set up.
* The [force variation parameter](https://help.optimizely.com/QA_Campaigns_and_Experiments/Force_behaviors_in_Optimizely_X_using_query_parameters) needs to be enabled. It can be enabled by going to the Settings tab in Optimizely, then make sure the "Disable force variation parameter" box is unchecked.

## Optimizely Setup

1. In Optimizely: go to _Settings_ > _Integrations_ > _Create Analytics Integration..._ > _Using JSON_
2. Copy and paste the following code into the _JSON Code_ window in Optimizely and click _Create Integration_.

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
3. Select _Crazy Egg_ in the integration list and enable the integration.
4. Find the experiment in Optimizely that you want to integrate Crazy Egg with, click on the Integrations tab and make sure the HeatMaps field is "ON".
5. You'll need your experiment's variation IDs. You can find them in Optimizely UI under Experiments.  Choose the Experiment you want to integrate, and click on API Names. Under the Variations section, you will find the IDs. Write these down.

## Crazy Egg Setup

* In Crazy Egg, create a snapshot for each ID. The snapshot URL will need to have the experiment page URL appended with `optimizely_x` query param. Example: https://www.example.com/my-page/?optimizely_x=VARIATIONID.
* Under the advanced settings - Tracking Options, select the Track by name option and enter the variationID in the text box.
