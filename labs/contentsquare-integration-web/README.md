# ContentSquare Integration for Optimizely Web

Hello! This integration allows you to send experiment and variation data from Optimizely into ContentSquare. 
## Pre-requisites

You need a ContentSquare and Optimizely Web account. 

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
  "name": "ContentSquare",
  "form_schema": [],
  "description": "",
  "options": {
    "track_layer_decision": "/*\n *Name: Optimizely CS Integration\n *Version: 3.0\n */\n(function () {\n    var tvp = \"AB_OP_\";\n\n    function sendToCS(csKey, csValue) {\n        csKey = tvp + csKey;\n\n        _uxa.push([\"trackDynamicVariable\", {\n            key: csKey,\n            value: csValue\n        }]);\n    };\n\n    function startOPIntegration() {\n    sendToCS(decisionString.experiment,decisionString.holdback ? decisionString.variation + ':holdback' : decisionString.variation);\n    }\n\n    function callback() {\n        if (!disableCallback) {\n            disableCallback = true;\n            startOPIntegration();\n\n            if (window.CS_CONF) {\n                CS_CONF.integrations = CS_CONF.integrations || [];\n                CS_CONF.integrations.push(\"Optimizely\");\n            }\n        }\n    }\n\n    var decisionString = optimizely.get('state').getDecisionObject({\n  \t\t\t\"campaignId\": campaignId\n\t\t});\n  \n  \tif(!!decisionString) {\n    \tvar disableCallback = false;\n    \twindow._uxa = window._uxa || [];\n    \t_uxa.push([\"afterPageView\", callback]);\n    }\n  \n})();\n//Optimizely CS Integration End"
  }
}
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

    function startOPIntegration() {
        sendToCS(decisionString.experiment, decisionString.holdback ? decisionString.variation + ' [Holdback]' : decisionString.variation);
    }

    function callback() {
        if (!disableCallback) {
            disableCallback = true;

            var decisionString = optimizely.get('state').getDecisionObject({
                "campaignId": campaignId
            });

            if (!!decisionString) {
                startOPIntegration();
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
