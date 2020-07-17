# Optimizely Web and Full Stack Event Integration

This integration allows customers to use the Optimizely Web snippet to act as a Full Stack tracking snippet.

The script listens to every Web event (pageviews, clicks or custom) and dispatches an additional network request with the payload for Full Stack.

It supports value and revenue metrics. It also mirrors custom attributes from Web to Full Stack.

## Pre-requisites

- An Optimizely Web and Optimizely Full Stack account

## Implementation Steps

1. Copy the code snippet available [here](https://gist.github.com/davidsertillange-optimizely/4a2d9a04e9029f8fbb0ae8b36810ed31)

2. In this code snippet, update lines 20-26 with: 
 - `account_id`: the Optimizely account ID
 - `project_id`: the Full Stack project ID where you want the events to be dispatched to
 - `User_id`: the Full Stack User ID used in activate or isFeatureEnabled
 - `environmentKey`: the environment where the events should be dispatched to
 - `updateDatafile`: the time interval in ms of how often the Full Stack datafile will be refreshed in the frontend. Defaults to 86400 (1 day)

3. Make sure your Full Stack project has the events you want to mirror created. Go to the Full Stack project and create the Web events you want to mirror. **The API names need to match between the Web and Full Stack events.**

For example:
- In the Web project, I have a click event "Homepage clicks" with API name `123456790_homepage_clicks`
- In the Full Stack project, a custom event with the same name `123456790_homepage_clicks` needs to be created for this script to work.

4. In your Optimizely Web’s Project Javascript, add the updated code snippet (step 1)

5. Load your page and check the network tab for events going to `/events` with `"client_name": "Optimizely/fswebintegration"`

## Drawbacks

This integration dispatches 1 event per network request. This means that if you have many events mirrored, this could lead to a lot of network requests being dispatched.
