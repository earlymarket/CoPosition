window.COPO = window.COPO || {};
window.COPO.maps = {
  queueCalled: false,

  initMap(customOptions) {
    if (document.getElementById('map')._leaflet) return;
    L.mapbox.accessToken = 'pk.eyJ1IjoiZ2FyeXNpdSIsImEiOiJjaWxjZjN3MTMwMDZhdnNtMnhsYmh4N3lpIn0.RAGGQ0OaM81HVe0OiAKE0w';

    var defaultOptions = {
      maxZoom: 18,
      minZoom: 1
    }

    var options = $.extend(defaultOptions, customOptions);
    window.map = L.mapbox.map('map', 'mapbox.light', options );
    $(document).one('page:before-unload', COPO.maps.removeMap);
  },

  initMarkers(checkins, total) {
    map.once('ready', function() {
      COPO.maps.generatePath(checkins);
      COPO.maps.renderAllMarkers(checkins);
      COPO.maps.bindMarkerListeners(checkins);
      COPO.maps.loadAllCheckins(checkins, total);
      if (COPO.maps.allMarkers.getLayers().length) {
        map.fitBounds(COPO.maps.allMarkers.getBounds());
      } else {
        map.once('locationfound', function(e) {
          map.panTo(e.latlng);
        })
      }
    });
  },

  loadAllCheckins(checkins, total) {
    if (total === undefined) return;
    loadCheckins(2);

    function getCheckinData(page) {
      if ($('.c-devices.a-show').length !== 0) {
        return $.getJSON(`${window.location.href}/checkins?page=${page}&per_page=1000`)
      } else if($('.c-friends.a-show_device').length !== 0) {
        return $.getJSON(`${window.location.href}&page=${page}&per_page=1000`)
      } else {
        console.log('Page not recognised. No incremental loading.');
      }
    };

    function loadCheckins(page) {
      if (total > gon.checkins.length) {
        getCheckinData(page).then(function(data) {
          if(window.gon.total === undefined) return;
          console.log('Loading more checkins!');
          gon.checkins = gon.checkins.concat(data.checkins);
          COPO.maps.refreshMarkers(gon.checkins);
          page++;
          loadCheckins(page);
        });
      } else {
        console.log('All done!');
        Materialize.toast('All check-ins loaded', 3000);
        window.COPO.maps.fitBounds();
      };
    }
  },

  removeMap() {
    map.remove();
  },

  fitBounds() {
    if (COPO.maps.allMarkers.getLayers().length){
      map.fitBounds(COPO.maps.allMarkers.getBounds())
    }
  },

  queueRefresh(checkins) {
    COPO.maps.queueCalled = true;
    map.once('zoomstart', function(e) {
      map.removeEventListener('popupclose');
      COPO.maps.refreshMarkers(checkins);
    })
    map.once('popupclose', function(e) {
      COPO.maps.refreshMarkers(checkins);
    })
  },

  refreshMarkers(checkins) {
    map.removeEventListener('popupclose');
    map.removeEventListener('zoomstart');

    map.closePopup();
    if(COPO.maps.markers){
      map.removeLayer(COPO.maps.markers);
    }
    if(COPO.maps.last){
      map.removeLayer(COPO.maps.last);
    }
    COPO.maps.refreshPath(checkins);
    COPO.maps.renderAllMarkers(checkins);
    COPO.maps.bindMarkerListeners(checkins);
    COPO.maps.queueCalled = false;
  },

  renderAllMarkers(checkins) {
    let markers = checkins.slice(1).map(checkin => COPO.maps.makeMarker(checkin));
    // allMarkers is used for calculating bounds
    COPO.maps.allMarkers = L.markerClusterGroup().addLayers(markers);
    COPO.maps.addLastCheckinMarker(checkins);
    // markers and last are distinct because we want the last checkin
    // to always be displayed unclustered
    COPO.maps.markers = L.markerClusterGroup().addLayers(markers, { chunkedLoading: true });
    map.addLayer(COPO.maps.markers);
  },

  addLastCheckinMarker(checkins) {
    if(!checkins.length) return;
    COPO.maps.last = COPO.maps.makeMarker(checkins[0], {
      icon: L.mapbox.marker.icon({ 'marker-symbol' : 'marker', 'marker-color' : '#47b8e0' }),
      title: 'ID: ' + checkins[0].id + ' - Most recent',
      alt: 'lastCheckin',
      zIndexOffset: 1000
    });
    COPO.maps.allMarkers.addLayer(COPO.maps.last);
    map.addLayer(COPO.maps.last);
  },

  bindMarkerListeners(checkins) {
    COPO.maps.allMarkers.eachLayer(function(marker) {
      COPO.maps.markerClickListener(checkins, marker);
    })
  },

  markerClickListener(checkins, marker) {
    marker.on('click', function(e) {
      let checkin = this.options.checkin;
      if(!marker._popup) {
        var template = COPO.maps.buildMarkerPopup(checkin);
        marker.bindPopup(L.Util.template(template, checkin));
        marker.openPopup();
      }
      if ($(".c-devices.a-show").length === 1) {
        $.get({
          url: "/users/"+gon.current_user_id+"/devices/"+checkin.device_id+"/checkins/"+checkin.id,
          dataType: "script"
        })
      }
      map.panTo(this.getLatLng());
      COPO.maps.w3w.setCoordinates(e);
    });
  },

  buildMarkerPopup(checkin) {
    let address = checkin.city;
    if(checkin.address){
      address = COPO.utility.commaToNewline(checkin.address)
    }
    var checkinTemp = {
      id: checkin.id,
      lat: checkin.lat.toFixed(6),
      lng: checkin.lng.toFixed(6),
      created_at: (new Date(checkin.created_at)).toUTCString(),
      address: address,
    };

    var foggedClass;
    checkin.fogged ? foggedClass = 'fogged enabled-icon' : foggedClass = ' disabled-icon';
    checkinTemp.foggedAddress = function() {
      if(checkin.fogged) {
        return '<li class="foggedAddress">Fogged address: ' + checkin.fogged_city + '</li>'
      }
    }
    checkinTemp.devicebutton = function(){
      if ($(".c-devices.a-index").length === 1) {
        return `<a href="./devices/${checkin.device_id}" title="Device map">${checkin.device}</a>`
      } else {
        return `<a href="${window.location.pathname}/show_device?device_id=${checkin.device_id}" title="Device map">${checkin.device}</a>`
      }
    }
    checkinTemp.inlineLat = COPO.utility.updateCheckinSpan(checkin, 'lat');
    checkinTemp.inlineLng = COPO.utility.updateCheckinSpan(checkin, 'lng');
    checkinTemp.foggle = COPO.utility.fogCheckinLink(checkin, foggedClass, 'fog');
    checkinTemp.deletebutton = COPO.utility.deleteCheckinLink(checkin);
    var template = $('#markerPopupTmpl').html();
    return Mustache.render(template, checkinTemp);
  },

  initControls(controls) {
    // When giving custom controls, I recommend adding layers last
    // This is because it expands downwards
    controls = controls || ['geocoder', 'locate', 'w3w', 'fullscreen', 'path', 'layers'];
    controls.forEach((control) => {
      let fn = this[control + 'ControlInit']
      if (typeof(fn) === 'function') {
        fn();
      }
    })
  },

  fullscreenControlInit() {
    L.control.fullscreen().addTo(window.map);
  },

  layersControlInit() {
    let map = window.map;
    L.control.layers({
      'Light': L.mapbox.tileLayer('mapbox.light'),
      'Dark': L.mapbox.tileLayer('mapbox.dark'),
      'Streets': L.mapbox.tileLayer('mapbox.streets'),
      'Hybrid': L.mapbox.tileLayer('mapbox.streets-satellite'),
      'Satellite': L.mapbox.tileLayer('mapbox.satellite'),
      'High Contrast': L.mapbox.tileLayer('mapbox.high-contrast')
    }, null, {position: 'topleft'}).addTo(map);
  },

  geocoderControlInit() {
    map.addControl(L.mapbox.geocoderControl('mapbox.places',
      { position: 'topright',
        keepOpen: true
      }
    ));
  },

  locateControlInit() {
    COPO.maps.lc = L.control.locate({
      follow: false,
      setView: 'always',
      markerClass: L.CircleMarker,
      strings: {
        title: 'Your current location',
        popup: 'Your current location within {distance} {unit}.<br><a href="#" id="current-location"></a>'
      }
    }).addTo(map);
  },

  w3wControlInit() {
    COPO.maps.w3w = new L.Control.w3w({apikey: '4AQOB5CT', position: 'topright'});
    COPO.maps.w3w.addTo(map);
  },

  pathControlInit() {
    const pathControl = L.Control.extend({
      options: {
        position: 'topleft' 
      },
      onAdd: function (map) {
        var container = L.DomUtil.create('div', 'leaflet-bar leaflet-control leaflet-control-custom');
        container.innerHTML = `
        <a class="leaflet-control-path leaflet-bar-path" href="#" onclick="return false;" title="View path">
          <i class="material-icons path-icon">timeline</i>
        </a>
        `
        container.onclick = function(){
          COPO.maps.pathControlClick();
        }
        return container;
      },
    });
    map.addControl(new pathControl());
  },

  mapPinIcon(public_id, color) {
    // The iconClass is a named Cloudinary transform
    // At the moment there are only three: 'map-pin' and
    // 'map-pin-blue' and 'map-pin-grey'
    var iconClass;
    color ? iconClass = `map-pin-${ color }` : iconClass = 'map-pin'
    return L.icon({
      iconUrl: $.cloudinary.url(public_id, {format: 'png', transformation: iconClass}),
      iconSize: [36,52],
      iconAnchor: [18,49]
    })
  },

  arrayToCluster: (markerArr, markerBuilderFn) => {
    if(!markerBuilderFn) {
      return console.error('Marker building function undefined')
    }
    let cluster = markerArr.map(marker => markerBuilderFn(marker))
      .filter(marker => marker);
    return L.markerClusterGroup().addLayers(cluster)
  },

  friendsCheckinsToCluster: (markerArr) => {
    let cluster = markerArr.map(marker => {
      let color;
      if(moment(marker.lastCheckin && marker.lastCheckin['created_at']).isBefore(moment().subtract(1, 'day'))){
        color = 'grey';
      }
      return COPO.maps.makeMapPin(marker, color);
    }).filter(marker => marker);
    return L.markerClusterGroup().addLayers(cluster)
  },

  makeMapPin(user, color, markerOptions) {
    let checkin = user.lastCheckin;
    if(checkin) {
      let public_id = user.userinfo.avatar.public_id;
      let defaults = {
        icon: COPO.maps.mapPinIcon(public_id, color),
        riseOnHover: true,
        user: $.extend(true, {}, user.userinfo),
        lastCheckin: checkin
      }
      markerOptions = $.extend({}, defaults, markerOptions)
      return L.marker([checkin.lat, checkin.lng], markerOptions)
    } else {
      return false
    }
  },

  addFriendMarkers(checkins){
    COPO.maps.friendMarkers = COPO.maps.bindFriendMarkers(checkins);
    map.addLayer(COPO.maps.friendMarkers);
    const BOUNDS = L.latLngBounds(
        _.compact(checkins.map(friend => friend.lastCheckin))
        .map(friend => L.latLng(friend.lat, friend.lng)))
    map.fitBounds(BOUNDS, {padding: [40, 40]})
  },

  bindFriendMarkers(checkins){
    let markers = COPO.maps.friendsCheckinsToCluster(checkins);
    markers.eachLayer((marker) => {
      marker.on('click', function (e) {
        COPO.maps.panAndW3w.call(this, e)
      });
      marker.on('mouseover', (e) => {
        if(!marker._popup) {
          COPO.maps.friendPopup(marker);
        }
        COPO.maps.w3w.setCoordinates(e);
        marker.openPopup();
      });
    });
    return markers
  },

  refreshFriendMarkers(checkins){
    if(COPO.maps.friendMarkers){ map.removeLayer(COPO.maps.friendMarkers) }
    COPO.maps.addFriendMarkers(checkins);
  },

  friendPopup(marker) {
    let user    = marker.options.user;
    let name    = COPO.utility.friendsName(user);
    let date    = moment(marker.options.lastCheckin.created_at).fromNow();
    let address = marker.options.lastCheckin.city;
    if(marker.options.lastCheckin.address){
      address = COPO.utility.commaToNewline(marker.options.lastCheckin.address)
    }
    let content = `
    <h2>${ name } <a href="./friends/${user.slug}" title="Device info">
      <i class="material-icons tiny">perm_device_information</i>
      </a></h2>
    <div class="address">${ address }</div>
    Checked in: ${ date }`
    marker.bindPopup(content, { offset: [0, -38] } );
  },

  makeMarker(checkin, markerOptions) {
    let defaults = {
      icon: L.mapbox.marker.icon({ 'marker-symbol' : 'marker', 'marker-color' : '#ff6900' }),
      title: 'ID: ' + checkin.id,
      alt: 'ID: ' + checkin.id,
      checkin: checkin
    }
    if(checkin.edited){
      map.panTo([checkin.lat, checkin.lng]);
    }
    markerOptions = $.extend({}, defaults, markerOptions)
    return L.marker([checkin.lat, checkin.lng], markerOptions)
  },

  userToLatlng(user) {
    let checkin = user.lastCheckin;
    if(checkin) {
      return L.latLng(checkin.lat, checkin.lng)
    }
  },

  panAndW3w(e) {
    map.panTo(this.getLatLng());
    COPO.maps.w3w.setCoordinates(e);
  },

  centerMapOn(lat, lng){
    map.setView(L.latLng(lat, lng), 18);
  },

  generatePath(checkins){
    const latLngs = checkins.map((checkin) => [checkin.lat, checkin.lng]);
    COPO.maps.checkinPath = L.polyline(latLngs, {color: 'red'});
  },

  refreshPath(checkins) {
    const path = COPO.maps.checkinPath;
    COPO.maps.generatePath(checkins);
    if(path && path._map){
      map.removeLayer(path);
      COPO.maps.checkinPath.addTo(map);
    }  
  },

  pathControlClick() {
    if(COPO.maps.checkinPath && COPO.maps.checkinPath._map){
      $('.path-icon').removeClass('path-active')
      map.removeLayer(COPO.maps.checkinPath);
    } else {
      $('.path-icon').addClass('path-active')
      COPO.maps.checkinPath.addTo(map);
    }
  },
}
