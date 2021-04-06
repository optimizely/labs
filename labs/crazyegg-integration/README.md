# Crazy Egg Integration

Crazy Egg integration allows you to see heatmaps with Optimizely data. For more information on how to use this integration, please take a look at this Knowledge Base article: https://help.optimizely.com/Integrate_Optimizely_with_Crazyegg

## Pre-requisites

* You'll need a Crazy Egg account. Head here to get started: [https://www.crazyegg.com](https://www.crazyegg.com).
* You'll need an Optimizely account with at least one experiment set up.
* The [force variation parameter](https://help.optimizely.com/QA_Campaigns_and_Experiments/Force_behaviors_in_Optimizely_X_using_query_parameters) needs to be enabled. It can be enabled by going to the Settings tab in Optimizely, then make sure the "Disable force variation parameter" box is unchecked.

## Installation

1. Download the integration's resources file from the left-hand side of this page.
1. Unzip the resources file.
1. In Optimizely: go to _Settings_ > _Integrations_ > _Create Analytics Integration…_ > _Using JSON_
1. Copy and paste the contents of _config.json_ (which was unzipped in a previous step) into the _JSON Code_ window in Optimizely and click _Create Integration_.
1. Select _Crazy Egg_ in the integration list and enable the integration.
1. In Optimizely, head into the experiment you want to integrate Crazy Egg with, click on the Integrations tab and make sure the HeatMaps field is set to "ON".

## Usage

* In _Optimizely_, get your experiment's variation IDs. You can get them by going to the experiment in the _Optimizely UI_, clicking onto the experiment you want to integrate, and clicking on API Names. You will find the variation IDs in the _Variations_ section. Write down the IDs.
* In _Crazy Egg_ for each variant from the above step, create a _snapshot_ by providing the experiment page url appended with `optimizely_x` queryparam. Example: https://www.example.com/my-page/?optimizely_x=`VARIATIONID`. 
In _advanced settings_ select `Track by name`, and provide the `variationId` in the text box.


