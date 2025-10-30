# Contentsquare Integration for Optimizely Web

Hello! This integration allows you to send experiment and variation data from Optimizely into Contentsquare. 
## Pre-requisites

You need a Contentsquare and Optimizely Web account. 

### Installation

This integration is using [Optimizely's Custom Analytics feature](https://help.optimizely.com/Integrate_Other_Platforms/Custom_analytics_integrations_in_Optimizely_X). 

 1. Log into Optimizely at optimizely.com
 2. Navigate to the Optimizely project in which you want to use the integration
 3. Click on ***Settings*** in the left navigation bar, and then ***Integration***
 4. You'll see a blue button titled ***"Create New Analytics Integration..."***
 5. In the dropdown menu, select "Using JSON"
 6. Paste the following code: 

```json
{
  "plugin_type": "analytics_integration",
  "name": "Contentsquare",
  "form_schema": [],
  "description": "This integration allows you to send the experiment and variation data from Optimizely Web to Contentsquare",
  "options": {
    "track_layer_decision": "/*\n *Name: Optimizely CS Integration\n *Version: 2.1\n */\n(function () {\n    var tvp = \"AB_OP_\";\n\n    function sendToCS(csKey, csValue) {\n        csKey = tvp + csKey;\n\n        _uxa.push([\"trackDynamicVariable\", {\n            key: csKey,\n            value: csValue\n        }]);\n    };\n\n    function startOPIntegration(decisionString) {\n        sendToCS(decisionString.experiment, decisionString.holdback ? decisionString.variation + ' [Holdback]' : decisionString.variation);\n    }\n\n    function callback() {\n        if (!disableCallback) {\n            disableCallback = true;\n\n            var decisionString = optimizely.get('state').getDecisionObject({\n                \"campaignId\": campaignId\n            });\n\n            if (!!decisionString) {\n                startOPIntegration(decisionString);\n            }\n\n            if (window.CS_CONF) {\n                CS_CONF.integrations = CS_CONF.integrations || [];\n                CS_CONF.integrations.push(\"Optimizely\");\n            }\n        }\n    }\n\n    var disableCallback = false;\n    window._uxa = window._uxa || [];\n    _uxa.push([\"afterPageView\", callback]);\n\n})();"
  }
}
```

### Using the integration

Before using this integration, you'll need to enable it in the [project settings](https://help.optimizely.com/Integrate_Other_Platforms/Custom_analytics_integrations_in_Optimizely_X#Enable_an_integration).

Moving forward, this integration will be turned on by default for every new experiment you create in Optimizely Web. 

We recommend to run an A/A experiment to validate that you are able to see data coming through in Contentsquare. 

If everything works properly, you should see in Contentsquare a Dynamic Variable called `AB_OP_` followed by the experiment name or id.	 
Example: `AB_OP_(18180652355)` where 18180652355 is the experimentId. The value of this Contentsquare dynamic variable will be the variation Ids of this experiment. 

### Integration Code

If you're interested in checking out the code that powers this integration, here it is:
```javascript
/*
 *Name: Optimizely CS Integration
 *Version: 2.1
 */
(function () {
    var tvp = "AB_OP_";

    function sendToCS(csKey, csValue) {
        csKey = tvp + csKey;

        _uxa.push(["trackDynamicVariable", {
            key: csKey,
            value: csValue
        }]);
    };

    function startOPIntegration(decisionString) {
        sendToCS(decisionString.experiment, decisionString.holdback ? decisionString.variation + ' [Holdback]' : decisionString.variation);
    }

    function callback() {
        if (!disableCallback) {
            disableCallback = true;

            var decisionString = optimizely.get('state').getDecisionObject({
                "campaignId": campaignId
            });

            if (!!decisionString) {
                startOPIntegration(decisionString);
            }

            if (window.CS_CONF) {
                CS_CONF.integrations = CS_CONF.integrations || [];
                CS_CONF.integrations.push("Optimizely");
            }
        }
    }

    var disableCallback = false;
    window._uxa = window._uxa || [];
    _uxa.push(["afterPageView", callback]);

})();
```
