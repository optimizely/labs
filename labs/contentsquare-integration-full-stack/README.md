# ContentSquare Integration

Hello! This integration allows you to send data from Optimizely Full Stack into ContentSquare.

## Pre-requisites

You need a ContentSquare and Optimizely account. 

### Installation

This integration uses [Optimizely's Notification Listeners](https://docs.developers.optimizely.com/full-stack/docs/set-up-notification-listener-swift) to retrieve the Optimizely experiment and variation data and send them to ContentSquare. 

This integration is built to be used with Optimizely's Full Stack client-side SDKs (Javascript, React, React Native). Server-side Optimizely Full Stack SDKs are ***not*** supported by this integration. 

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
