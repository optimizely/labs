# Crazy Egg Integration

The Crazy Egg integration allows you to see heatmaps with Optimizely data. 

## Pre-requisites

* You'll need a Crazy Egg account. Head here to get started: [https://www.crazyegg.com](https://www.crazyegg.com).
* You'll need an Optimizely Web project with at least one experiment set up.
* The [force variation parameter](https://help.optimizely.com/QA_Campaigns_and_Experiments/Force_behaviors_in_Optimizely_X_using_query_parameters) needs to be enabled. It can be enabled by going to the Settings tab in Optimizely, then make sure the "Disable force variation parameter" box is unchecked.

## Optimizely Setup

1. Download the integration Resource file located on the left side of this page.
2. Unzip the resources file.
3. In Optimizely: go to _Settings_ > _Integrations_ > _Create Analytics Integration…_ > _Using JSON_
4. Copy and paste the contents of _config.json_ from step 2 into the _JSON Code_ window in Optimizely and click _Create Integration_.
5. Select _Crazy Egg_ in the integration list and enable the integration.
6. Find the experiment in Optimizely that you want to integrate Crazy Egg with, click on the Integrations tab and make sure the HeatMaps field is "ON".
7. You’ll need your experiment's variation IDs. You can find them in Optimizely UI under Experiments.  Choose the Experiment you want to integrate, and click on API Names. Under the Variations section, you will find the IDs. Write these down.

## Crazy Egg Setup

* In Crazy Egg, create a snapshot for each ID. The snapshot URL will need to have the experiment page URL appended with `optimizely_x` query param. Example: https://www.example.com/my-page/?optimizely_x=`VARIATIONID`. 
* Under the advanced settings - Tracking Options, select the Track by name option and enter the variationID in the text box.
