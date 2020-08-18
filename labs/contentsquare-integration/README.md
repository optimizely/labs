# ContentSquare Integration

Hello! This integration allows you to send data from Optimizely into ContentSquare. This integration is made up of 2 parts: an integration for Optimizely Web and an integration for Optimizely Full Stack.

## Pre-requisites

You need a ContentSquare and Optimizely account. 


## ContentSquare and Optimizely Web

This integration is using [Optimizely's Custom Analytics feature](https://help.optimizely.com/Integrate_Other_Platforms/Custom_analytics_integrations_in_Optimizely_X). 

### Installation

 1. Log into Optimizely at optimizely.com
 2. Navigate to the Optimizely project in which you want to use the integration
 3. Click on ***Settings*** in the left navigation bar, and then ***Integration***
 4. You'll see a blue button titled ***"Create New Analytics Integration..."***
 5. In the dropdown menu, select "Using JSON"
 6. Paste the following code: 

```json
{"plugin_type": "analytics_integration",
"name": "ContentSquare Integration",
"form_schema": [],
"description": "This integration allows you to send the experiment and variation data from Optimizely Web to ContentSquare",
"options": {
"track_layer_decision": "function sendTestToCS(csKey, csValue) {\n window._uxa = window._uxa || [];\n window._uxa.push([\"trackDynamicVariable\", {key: csKey, value: csValue} ]);\n}\n\nfunction callback(context) {\n\tif (!disableCallback) {\n\t\tdisableCallback = true;\n\n\t\tif (window.CS_CONF) {\n CS_CONF.integrations = CS_CONF.integrations || [];\n CS_CONF.integrations.push(\"Optimizely Web\");\n\t\t}\n\t}\n}\n  \nvar disableCallback = false;\nwindow._uxa = window._uxa || [];\n_uxa.push([\"afterPageView\", callback]);\n\nvar csPrefix = 'AB_Opti_';\nvar csKey = csPrefix + campaignId + '_' + experimentId;\nvar csValue = variationId;\n\nsendTestToCS(decodeURI(csKey), decodeURI(csValue));"}}
```

### Using the integration

Before using this integration, you'll need to enable it in the [project settings](https://help.optimizely.com/Integrate_Other_Platforms/Custom_analytics_integrations_in_Optimizely_X#Enable_an_integration).

Moving forward, this integration will be turned on by default for every new experiment you create in Optimizely Web. 

We recommend to run an A/A experiment to validate that you are able to see data coming through in ContentSquare. 

If everything works properly, you should see in ContentSquare a Dynamic Variable called `AB_OP_` followed by the campaign Id and experiment Id.	 
Example: `AB_OP_18180652355_18182752153` where 18180652355 is the campaign Id and 18182752153 the experiment Id. The value of this ContentSquare dynamic variable will be the variation Ids of this experiment. 

### Integration Code

If you're interested in checking out the code that powers this integration, here it is:
```javascript
function sendTestToCS(csKey, csValue) {
    window._uxa = window._uxa || [];
    window._uxa.push(["trackDynamicVariable", {key: csKey, value: csValue} ]);
}

function callback(context) {
	if (!disableCallback) {
		disableCallback = true;

		if (window.CS_CONF) {
          CS_CONF.integrations = CS_CONF.integrations || [];
          CS_CONF.integrations.push("Optimizely Web");
		}
	}
}
     
var disableCallback = false;
window._uxa =  window._uxa || [];
_uxa.push(["afterPageView", callback]);

var csPrefix = 'AB_Opti_';
var csKey = csPrefix + campaignId + '_' + experimentId;
var csValue = variationId;

sendTestToCS(decodeURI(csKey), decodeURI(csValue));
```

## ContentSquare and Optimizely Full Stack

This integration uses [Optimizely's Notification Listeners](https://docs.developers.optimizely.com/full-stack/docs/set-up-notification-listener-swift) to retrieve the Optimizely experiment and variation data and send them to ContentSquare. 

This integration is built to be used with Optimizely's Full Stack client-side SDKs (Javascript, React, React Native). Server-side Optimizely Full Stack SDKs are ***not*** supported by this integration. 

### Installation


 -  Just after calling Optimizely's `createInstance()` method, run this code: 
```javascript
var optimizelyEnums = require('@optimizely/optimizely-sdk').enums;

function onDecision(decisionObject) {

	function callback(context) {
		if (!disableCallback) {
			disableCallback = true;
			if (window.CS_CONF) {
				CS_CONF.integrations = CS_CONF.integrations || [];
				CS_CONF.integrations.push("Optimizely Full Stack");
			}
		}
	}

	var disableCallback = false;
	_uxa.push(["afterPageView", callback]);

	var csPrefix = 'AB_OP_', csKey, csValue;
	csKey = csPrefix + decisionObject.experiment.key;
	csValue = decisionObject.variation.key;
	
	window._uxa = window._uxa || []; 
	window._uxa.push(["trackDynamicVariable", {key: csKey, value: csValue} ]);
}

// Replace OptimizelyClient with the name of your Optimizely SDK Instance (where createInstance is used)
optimizelyClient.notificationCenter.addNotificationListener(
	optimizelyEnums.NOTIFICATION_TYPES.ACTIVATE,
	onDecision,
);
```
- That's it! 

On every experiment activation (method `activate()` or `isFeatureEnabled` is invoked), then an Optimizely's Notification Listener will execute, grabbing the experiment data from Optimizely and will forward them to ContentSquare. 
### Using the integration

If everything works properly, you should see in ContentSquare a Dynamic Variable called `AB_OP_` followed by the campaign Id and experiment Id.	 
Example: `AB_OP_18180652355_18182752153` where 18180652355 is the campaign Id and 18182752153 the experiment Id. The value of this ContentSquare dynamic variable will be the variation Ids of this experiment. 

We recommend to run an A/A experiment to validate that you are able to see data coming through in ContentSquare. 
