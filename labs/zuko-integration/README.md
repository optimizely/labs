# Zuko Form Analytics Integration

The Zuko Form Analytics integration for Optimizely automatically tracks the experiments and variations which your form visitors have been assigned to as custom attributes in Zuko.
This allows you to segment your data based on the experiments and variations that your form visitors have seen.

## Pre-requisites

* You'll need a Zuko Form Analytics account. Head here to get started: [https://www.zuko.io/get-started](https://www.zuko.io/get-started).
* In Zuko, you'll need a form set up to track session data from your form. For help with this, check out our extensive guides, here: [https://www.zuko.io/guides](https://www.zuko.io/guides).
* You'll need an Optimizely account with at least one experiment set up. The experiment will need to be running on the same URL that you’ve set Zuko up to track your form on, above.

## Installation

1. Download the integration's resources file from the left-hand side of this page.
1. Unzip the resources file.
1. In Optimizely: go to _Settings_ > _Integrations_ > _Create Analytics Integration…_ > _Using JSON_
1. Copy and paste the contents of _config.json_ (which was unzipped in a previous step) into the _JSON Code_ window in Optimizely and click _Create Integration_.
1. Select _Zuko Form Analytics_ in the integration list and enable the integration.
1. Enable the _Zuko Form Analytics_ integration in your experiment in Optimizely.

## Usage

* When the Zuko integration for Optimizely is enabled for an experiment it will automatically track the experiments and their respective variations which a user has been assigned to by Optimizely.
* When viewing session data in the Zuko app, you are then able to segment your session data on the experiments and variations that your visitors have seen.
* This is available in the _Select a filter..._  drop down menu in the top-right of the Zuko app.
