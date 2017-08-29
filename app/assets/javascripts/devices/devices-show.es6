$(document).on('page:change', function() {
  var U = window.COPO.utility;

  if (U.currentPage('friends', 'show_device') || U.currentPage('devices', 'show')) {
    var page = U.currentPage('devices', 'show') ? 'user' : 'friend'
    var fogged = false;
    var currentCoords;
    var M = window.COPO.maps;
    U.gonFix();
    M.initMap();
    initMarkers();
    var controls = ['geocoder', 'locate', 'w3w', 'fullscreen', 'path']
    page === 'user' ? controls.push('locations', 'layers') : controls.push('layers')
    M.initControls(controls);
    COPO.datePicker.init();

    map.on('locationfound', onLocationFound);

    if (page === 'user') {
      $('.modal-trigger').leanModal();
      M.createCheckinPopup();
      M.rightClickListener();
      M.checkinNowListeners(getLocation);
      window.COPO.editCheckin.init();
    }

    function postLocation(position) {
      $.ajax({
        url: '/users/' + gon.current_user_id + '/devices/' + gon.device + '/checkins/',
        type: 'POST',
        dataType: 'script',
        data: { checkin: { lat: position.coords.latitude, lng: position.coords.longitude, fogged: fogged } }
      });
    }

    function getLocation(checkinFogged) {
      fogged = checkinFogged;
      if (currentCoords) {
        var position = { coords: { latitude: currentCoords.lat, longitude: currentCoords.lng } }
        postLocation(position)
      } else {
        navigator.geolocation.getCurrentPosition(postLocation, U.geoLocationError, { timeout: 5000 });
      }
    }

    function onLocationFound(p) {
      currentCoords = p.latlng;
    }

    function initMarkers() {
      if (gon.total > gon.MAX_CHECKINS_TO_DISPLAY) {
        M.initMarkers(gon.locations);
      } else {
        M.initMarkers(gon.checkins, gon.total);
      }
    }
  }
});
