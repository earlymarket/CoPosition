$(document).on('page:change', function() {
  let U = window.COPO.utility;
  if (U.currentPage('approvals', 'new') && typeof gon != "undefined") {
    let submitted = false;
    (window.location.search.includes("User") ? U.setActivePage('friends') : U.setActivePage('apps'));
    $(".search .devs_typeahead").typeahead({
      hint: true,
      highlight: true,
      minLength: 1
    },
    {
      name: 'devs',
      source: U.substringMatcher(gon.devs)
    });

    $("form#new_approval").submit(function (e) {
      if (window.location.search.includes("Developer") || submitted) return
      let friendEmail = $("#approval_approvable")[0].value
      let match = gon.users.find((email) => email === $.md5(friendEmail))
      if (match) return
      e.preventDefault()
      swal({
        title: "Are you sure?",
        text: "This email isn't associated with a Coposition user. Do you wish to send an invite to join Coposition? They will be able to accept your friend request after registering.",
        buttons: {
          cancel: {
            text: "Cancel",
            visible: true
          },
          confirm: {
            text: "Invite",
            closeModal: false
          }
        }
      })
      .then(willInvite => {
        if (willInvite) {
          swal(`Your invite to join Coposition has been sent to ${friendEmail}!`, {
            icon: "success"
          })
          submitted = true
          $("form#new_approval").submit()
        }
      })
    })
  }
})
