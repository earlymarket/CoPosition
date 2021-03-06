$(document).on('page:change', function() {
  if (window.COPO.utility.currentPage('devices', 'index')) {
    const U = window.COPO.utility;
    const MAPS  = window.COPO.maps;
    const P = window.COPO.permissionsTrigger;
    MAPS.initMap();
    MAPS.initControls(['locate', 'w3w', 'fullscreen', 'layers']);
    U.gonFix();
    U.setActivePage('devices')
    COPO.permissions.initSwitches('devices', gon.current_user_id, gon.permissions)
    COPO.delaySlider.initSliders(gon.devices);
    gon.checkins && gon.checkins.length ? COPO.maps.initMarkers(gon.checkins) : $('#map-overlay').removeClass('hide');

    $('#find-checkin').on('click', checkinSearch)

    function checkinSearch () {
      let userId = gon.current_user_id
      let checkinId = $('#checkin_id').val()
      if (checkinId.length) {
        window.location = `/users/${userId}/devices/nil/checkins/${checkinId}`
      } else {
        M.toast({html: 'Please enter a check-in ID', displayLength: 3000, classes: 'red'});
      }
    }
    
    $('body').on('click', '.edit-button', function (e) {
      e.preventDefault();
      $(this).toggleClass('hide', true);
      makeEditable($(this).prev('span'), handleEdited);
    });

    function makeEditable ($target, handler) {
      let original = $target.text();
      $target.attr('contenteditable', true);
      $target.focus();
      document.execCommand('selectAll', false, null);
      $target.on('blur', function () {
        handler(original, $target);
      });
      $target.on('keydown', function (e) {
        if(e.which === 27 || e.which === 13 ) {
          handler(original, $target);
        }
      });
      $target.on('click', function (e) {
        e.preventDefault();
      });
      return $target;
    }

    function handleEdited (original, $target) {
      var newName = $target.text().replace(/ /g, '_')
      if (original !== newName) {
        var url = $target.parents('a').attr('href');
        $.ajax({
          dataType: 'json',
          url: url,
          type: 'PUT',
          data: { device: { name: newName } }
        })
        .done(function (response) {
        })
        .fail(function (error) {
          $target.text(original);
          M.toast({html: 'Name: ' + JSON.parse(error.responseText).name, displayLength: 3000, classes: 'red'});
        })
      }
      $target.text(newName);
      $target.next().toggleClass('hide', false);
      U.deselect();
      $target.off();
      $target.attr('contenteditable', false);
    }

    window.initPage = function(){
      P.initTrigger('devices');
      $('.modal-trigger').modal();
      $('.clip_button').off();
      U.initClipboard();
      $('.tooltipped').tooltip({delay: 50});
      $('.linkbox').off('touchstart click');

      $('.linkbox').on('click', function(e){
        this.select()
      })

      //backup for iOS
      $('.linkbox').on('touchstart', function(){
        this.focus();
        this.setSelectionRange(0, $(this).val().length);
      })

      $('.linkbox').each(function(i,linkbox){
        $(linkbox).attr('size', $(linkbox).val().length)
      })

      $('.center-map').on('click', function() {
        const device_id = this.dataset.device;
        const checkin = gon.checkins.find((checkin) => checkin.device_id.toString() === device_id);
        if(checkin) {
          U.scrollTo('#quicklinks', 200);
          setTimeout(() => MAPS.centerMapOn(checkin.lat, checkin.lng), 200);
        }
      });

      $('.fogButton').each((index, fogButton) => {
        if(!$(fogButton).data('fogged')){
          $(fogButton).removeData('confirm').removeAttr('data-confirm')
        }
      })

      $('.cloakedButton').each((index, cloakedButton) => {
        if($(cloakedButton).data('cloaked')){
          $(cloakedButton).removeData('confirm').removeAttr('data-confirm')
        }
      })
    }
    initPage();

    $(document).one('turbolinks:before-render', function(){
      COPO.permissions.switchesOff();
      $(window).off("resize");
      $('body').off('click', '.edit-button');
    })
  }
})
