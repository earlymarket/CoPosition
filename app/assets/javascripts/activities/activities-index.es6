$(document).on('page:change', function() {
  if (window.COPO.utility.currentPage('activities', 'index')) {
    const substringMatcher = (strs) => {
      return (query, callback) => {
        let matches = [];
        let substrRegex = new RegExp(query, 'i');
        $.each(strs, (i, str) => {
          if (substrRegex.test(str)) {
            matches.push(str);
          }
        });
        callback(matches);
      };
    };

    $('.search .users_typeahead').typeahead({
      hint: true,
      highlight: true,
      minLength: 1
    },
    {
      name: 'users',
      source: substringMatcher(gon.users)
    });
  }
})
