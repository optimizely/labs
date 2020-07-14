# Static Site Feature Flags
_Note: Turn off any ad-blockers! Ad-blockers can prevent this demo from working._

[Feature flags](https://www.optimizely.com/optimization-glossary/feature-flags/?) enable a powerful continuous delivery process and provide a platform for [progressive delivery](https://www.optimizely.com/optimization-glossary/progressive-delivery/) with phased rollouts and [A/B tests](https://www.optimizely.com/optimization-glossary/ab-testing/).

However, feature flags installed in a static site can be difficult because there's usually not a backing database tracking users in a static site.

In this step-by-step lab, you'll see how to integrate feature flags into a static site with a free version of
Optimizely, [Optimizely Rollouts](https://www.optimizely.com/rollouts-signup/?utm_source=labs&utm_campaign=static-site-feature-flags-lab)

## Pre-requisites
- A modern web browser

## Steps

_Note: You can also follow along [this video](https://youtu.be/Q7xjIvQf2G4) with the instructions below_

1. Create an [Optimizely Rollouts Account](https://www.optimizely.com/rollouts-signup/?utm_source=labs&utm_campaign=static-site-feature-flags-lab)
2. Open up a [blank codepen](https://codepen.io/asametrical/pen/PoPPXbQ?editors=1000)
3. Create a static site by pasting in the following html:
```
<html>
  <head>
  </head>
  <body>
    <h1>Hello World</h1>
    <p id="subtitle">This is a subtitle</p>
  </body>
</html>
```

4. Install the Optimizely SDK via the [html script tag](https://docs.developers.optimizely.com/rollouts/docs/install-sdk-javascript) by placing the below code within the `<head></head>` tags of the html. This makes the SDK available at `window.optimizelySdk`:
```
    <script src="https://unpkg.com/@optimizely/optimizely-sdk@3.5/dist/optimizely.browser.umd.min.js"></script>
```

5. Install the datafile for your project using the [html script tag](https://docs.developers.optimizely.com/rollouts/docs/initialize-sdk-javascript) by placing the below code within the `<head></head>` tags of the html. Be sure to replace `Your_SDK_Key` with your SDK key from the [Optimizely Application](https://app.optimizely.com). This makes the SDK available at `window.optimizelyDatafile`:
```
    <script src="https://cdn.optimizely.com/datafiles/<Your_SDK_KEY>.json/tag.js"></script>
```

You can find your SDK Key in the Optimizely application by navigating to the far left 'Settings' > 'Environments' and copy the Development SDK Key value.

![Screenshot](https://raw.githubusercontent.com/optimizely/labs/master/assets/optimizely-screenshots/sdk-key.gif)

6. Place the following script tag near the bottom of the html within the `<html>` tag, which will initialize the SDK:
```
  <script>
    var optimizelyClientInstance = window.optimizelySdk.createInstance({
      datafile: window.optimizelyDatafile,
    });
  </script>
```
7. Create a feature flag named `hello_world` in the [Optimizely UI](https://app.optimizely.com). Navigate to 'Features > Create New Feature' and create a feature flag called 'hello_world':

![Screenshot](https://raw.githubusercontent.com/optimizely/labs/master/assets/optimizely-screenshots/create-flag.gif)

9. Implement the `hello_world` feature flag by placing the following code just below our initialization code above:
```
    var userId = 'user123';
    var enabled = optimizelyClientInstance.isFeatureEnabled('hello_world', userId);
    if (enabled) {
      document.querySelector("#subtitle").innerText = "Feature flag is ON!"
    } else {
      document.querySelector("#subtitle").innerText = "Feature flag is off"
    }
```
9. Define a function to get or generate userIds and replace `user123` with `getOrGenerateUserId()`:
```
    function getOrGenerateUserId() {
      var userId;
      try {
        var storageKey = 'optimizely-userId'
        userId = window.localStorage.getItem(storageKey);
        if (!userId) {
          userId = String(Math.random());
          localStorage.setItem(storageKey, userId);
        }
      } catch {
        console.warn('[OPTIMIZELY] LocalStorage not available to store userId. Generating random userId each page load');
        userId = String(Math.random());
      }
      return userId;
    }

    var userId = getOrGenerateUserId();
```

10. Now you can turn the feature flag on and off in the Optimizely UI and see the changes in your static site! 🎉

A full code sample is here:
```
<html>
  <head>
    <script src="https://unpkg.com/@optimizely/optimizely-sdk@3.5/dist/optimizely.browser.umd.min.js"></script>
    <script src="https://cdn.optimizely.com/datafiles/V7kE2tbrJaYGmtRF5W5QXf.json/tag.js"></script>
  </head>
  <body>
    <h1>Hello World</h1>
    <p id="subtitle">This is a subtitle</p>
  </body>
  <script>
    var optimizely = optimizelySdk.createInstance({
      datafile: window.optimizelyDatafile,
    });

    function getOrGenerateUserId() {
      var userId;
      try {
        var storageKey = 'optimizely-userId'
        userId = window.localStorage.getItem(storageKey);
        if (!userId) {
          userId = String(Math.random());
          localStorage.setItem(storageKey, userId);
        }
      } catch {
        console.warn('[OPTIMIZELY] LocalStorage not available to store userId. Generating random userId each page load');
        userId = String(Math.random());
      }
      return userId;
    }

    var userId = getOrGenerateUserId();
    var enabled = optimizelyClientInstance.isFeatureEnabled('hello_world', userId);
    if (enabled) {
      document.querySelector("#subtitle").innerText = "Feature flag is ON!"
    } else {
      document.querySelector("#subtitle").innerText = "Feature flag is off"
    }
  </script>
</html>
```
