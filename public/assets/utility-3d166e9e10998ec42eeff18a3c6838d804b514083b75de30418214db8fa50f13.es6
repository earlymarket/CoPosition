/* exported utility */


window.COPO = window.COPO || {};

COPO.utility = {

  deselect() {
    if (window.getSelection) {
      if (window.getSelection().empty) {  // Chrome
        window.getSelection().empty();
      } else if (window.getSelection().removeAllRanges) {  // Firefox
        window.getSelection().removeAllRanges();
      }
    } else if (document.selection) {  // IE?
      document.selection.empty();
    }
  },
  urlParam(name) {
    var results = new RegExp('[\?&]' + name + '=([^&#]*)').exec(window.location.href);
    if (!results) return null;
    return results[1] || 0;
  },

  ujsLink(verb, text, path) {
    var output =  $('<a data-remote="true" rel="nofollow" data-method="' + verb +'" href="' + path +'">' + text +'</a>')
    return output
  },

  deleteCheckinLink(checkin) {
    return COPO.utility.ujsLink('delete',
      '<i class="material-icons right red-text">delete_forever</i>' ,
      window.location.pathname + '/checkins/' + checkin.id )
      .attr('class', 'right').attr('data-confirm', 'Are you sure?').prop('outerHTML')
  },

  fogCheckinLink(checkin, foggedClass, fogId) {
    return COPO.utility.ujsLink('put',
      '<i class="material-icons">cloud</i>' ,
      window.location.pathname + '/checkins/' + checkin.id )
      .attr('id', fogId + checkin.id).attr('class', foggedClass).prop('outerHTML')
  },

  renderInlineCoords(checkin) {
    const url = `${window.location.pathname}/checkins/${checkin.id}`;
    return `<span class="editable-wrapper clickable">
              <span class="editable" data-url="${url}">${checkin.lat.toFixed(6)}, ${checkin.lng.toFixed(6)}</span>
              <i class="material-icons grey-text edit-coords">mode_edit</i>
            </span>`;
  },

  geocodeCheckinLink(checkin) {
    return COPO.utility.ujsLink('get',
      'Get address' ,
      window.location.pathname + '/checkins/' + checkin.id )
      .prop('outerHTML')
  },

  createCheckinLink(coords) {
    var checkin = {
      'checkin[lat]': coords.lat.toFixed(6),
      'checkin[lng]': coords.lng.toFixed(6)
    }
    var checkinPath = location.pathname + '/checkins?' + $.param(checkin);
    return COPO.utility.ujsLink('post', 'Create checkin here', checkinPath).prop('outerHTML');
  },

  friendsName(friend) {
    return friend.username ? friend.username : friend.email.split('@')[0]
  },

  fadeUp(target) {
    $(target).velocity({
      opacity: 0,
      marginTop: '-40px'
    }, {
      duration: 375,
      easing: 'easeOutExpo',
      queue: false,
      complete() {
        $(target).remove();
      }
    });
  },

  avatar(avatar, options) {
    options = $.extend(this.avatarDefaults, options)
    if(avatar) {
      return $.cloudinary.image(avatar.public_id, options).prop('outerHTML')
    }
  },

  avatarUrl(avatar, options) {
    options = $.extend(this.avatarDefaults, options)
    if(avatar) {
      return $.cloudinary.url(avatar.public_id, options)
    }
  },

  avatarDefaults: {"transformation":["60x60cAvatar"],"format":"png"},

  initClipboard() {
    let clipboard = new Clipboard('.clip_button');

    clipboard.on('success', function(e) {
      $('.material-tooltip').children('span').text('Copied');
      e.clearSelection();
    });

    clipboard.on('error', function(e) {
      let  action = e.action;
      let  actionMsg = '';
      let  actionKey = (action === 'cut' ? 'X' : 'C');
      if (/iPhone|iPad/i.test(navigator.userAgent)) {
        actionMsg = 'Touch the copy button above the keyboard';
      } else if (/Mac/i.test(navigator.userAgent)) {
        actionMsg = 'Press ⌘-' + actionKey + ' to ' + action;
      } else {
        actionMsg = 'Press Ctrl-' + actionKey + ' to ' + action;
      }
      $('.material-tooltip').children('span').text(actionMsg);
      // console.error('Action:', e.action);
      // console.error('Trigger:', e.trigger);
    });
  },

  gonFix() {
    var contents = $('#gonvariables').html();
    $('#gonvariables').html(contents);
  },

  commaToNewline(string) {
    return string.replace(/, /g, '\n')
  },

  geoLocationError(err) {
    Materialize.toast('Could not get location', 3000)
  },

  pluralize(noun, count) {
    if(count > 1) return noun + 's';
    return noun;
  },

  scrollTo(selector, speed) {
    speed = speed || 200;
    $('html, body').animate({
      scrollTop: $(selector).offset().top
    }, speed);
  },

  padStr(char, length, str) {
    // leftpads str using char until it is at least length
    const diff = parseInt(length) - String(str).length;
    return diff > 0 ? String(char).repeat(diff) + str : str;
  },

  validateLatLng(coord) {
    return Math.abs(coord) < 180;
  }
};