# Coposition
[![Build Status](https://travis-ci.org/earlymarket/CoPosition.svg?branch=master)](https://travis-ci.org/earlymarket/CoPosition)
[![Code Climate](https://codeclimate.com/github/earlymarket/CoPosition/badges/gpa.svg)](https://codeclimate.com/github/earlymarket/CoPosition)
[![Test Coverage](https://codeclimate.com/github/earlymarket/CoPosition/badges/coverage.svg)](https://codeclimate.com/github/earlymarket/CoPosition/coverage)

## What's it all about?

### For users
You go an a website. Let's call it ~~Facebook~~ LifeInvader.

LifeInvader will immediately start tracking your location. :eyes:

But, if LifeInvader used Coposition, you'd have to specify which of your devices it can see. :cop:

Keeping your data yours. :thumbsup:


### For the developers
A very easy to use HTTP REST API, giving you some cool location-aware data. :neckbeard:

Instant trust from your users. :innocent:

Open source. If you see something you think could be improved, improve it! :shipit:


## Example usage with demo app

### Setup Coposition
- Sign up on [coposition.com](http://coposition.com)
- Go to Dashboard > Devices > Add current device
- Enter a friendly name for your current device

### Use Whereforartthou
- Sign up on [whereforartthou.com](http://whereforartthou.com/)
- Enter some sign up information (Does not need to relate to Coposition in any way)
- Enter your Coposition username when prompted

Have a go at messing around with your Coposition permissions, and see how it affects WFAT

--------
# Setup

Add the following routes to your /etc/hosts

127.0.0.1    api.coposition-dev.com

127.0.0.1    coposition-dev.com

`bundle`

`rake db:create && rake db:migrate && rake db:seed`

## Example API usage

Create a user with the username `testuser`.

Create a developer.

Note the API key.

### Create a device

To start posting a checkin, you need to tell us which device you're posting to.
This is determined by the UUID of the device.
If you're creating a new device, all you need to do is request a new UUID

`GET http://api.coposition.com/v1/uuid`
With `X-API-KEY: YourApiKey` passed as a header

### Posting a checkin

`POST http://api.coposition-dev.com/v1/checkins`
With the payload:
```
{
  "checkin": {
    "uuid":"07b47a50-6f22-468f-b387-b314768f4649",
    "lat":"51.588330",
    "lng":"-0.513069"
  }
}
```

If you then go to your Dashboard > Devices > Add a device, add the UUID `07b47a50-6f22-468f-b387-b314768f4649`, and the device will be bound to your account.

### Asking for approval

`POST http://api.coposition-dev.com/v1/users/testuser/approvals`
With `X-API-KEY: YourApiKey` passed as a header

If you go to the user dashboard, you'll now see an approval request from the company you created.

Approving this allows the company to have access to that user's location data of all devices (by default).

### Getting the device information

`GET http://api.coposition-dev.com/v1/users/testuser/devices`
With `X-API-KEY: YourApiKey` passed as a header
Returns an index of devices.




--------

### License
Copyright 2016 Earlymarket LLP
