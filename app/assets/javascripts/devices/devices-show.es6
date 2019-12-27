$(document).on('page:change', function() {
  var U = window.COPO.utility;
  if (U.currentPage('friends', 'show_device') || U.currentPage('devices', 'show') || U.currentPage('checkins', 'index')) {
    var fogged = false;
    var currentCoords;
    var MAPS = window.COPO.maps;
    U.gonFix();
    MAPS.initMap();
    initMarkers();
    var controls = ['geocoder', 'locate', 'w3w', 'fullscreen', 'path']
    U.currentPage('friends', 'show_device') ? controls.push('layers') : controls.push('cities', 'layers')
    MAPS.initControls(controls);
    COPO.datePicker.init();

    map.on('locationfound', onLocationFound);

    if (!U.currentPage('friends', 'show_device')) {
      U.setActivePage('devices')
      window.COPO.editCheckin.init();
    } else {
      U.setActivePage('friends')
    }

    if (U.currentPage('devices', 'show')) {
      $('.modal-trigger').modal();
      MAPS.createCheckinPopup();
      MAPS.rightClickListener();
      MAPS.checkinNowListeners(getLocation);
      window.COPO.editCheckin.init();
      if (!U.mobileCheck()) {
        M.toast({html: 'Right click map to check-in', displayLength: 3000})
      }
    }

    $('#deleteDevice').on('click', (e) => {
      swal({
        title: 'Enter device name to delete this device and check-ins',
        icon: 'warning',
        dangerMode: true,
        content: {
          element: 'input',
          attributes: {
            placeholder: 'Enter your device name',
            id: 'deviceName',
            type: 'text'
          }
        },
        buttons: {
          cancel: {
            text: 'Cancel',
            visible: true
          },
          confirm: {
            text: 'Delete',
            closeModal: false
          },
          download: {
            text: 'Delete and download check-ins',
            closeModal: false
          }
        }
      })
      .then((value) => {
        let deviceName = $('input#deviceName')[0].value
        if (!deviceName) return
        let match = gon.devices.find((device) => device.name === deviceName)
        if (match) {
          let route = `/users/${gon.current_user_id}/devices/`
          switch (value) {
            case 'delete':
              $.ajax({url: `${route}${gon.device}`, type: 'DELETE'}).then(swal.closeModal)
              break
            case 'download':
              window.open(`${route}${gon.device}.csv?download=csv&delete=true`)
              setTimeout(() => { window.location.href = route }, 500)
              break
          }
        } else {
          swal('Incorrect device name', 'The device name you entered did not match', 'error');
        }
      })
    })

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
      if (gon.checkin || U.currentPage('friends', 'show_device') || gon.checkins_view) {
        $('.checkins_view').val(true)
        MAPS.initMarkers(gon.checkins, gon.total)
      } else {
        MAPS.initMarkers(gon.cities, gon.total, true);
      }
    }
  }
});
