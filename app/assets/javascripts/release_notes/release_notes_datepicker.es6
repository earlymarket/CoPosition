$(document).on("page:change", function() {
  if (window.COPO.utility.currentPage("release_notes", "edit") || window.COPO.utility.currentPage("release_notes", "new")) {
    $('.release-datepicker').pickadate({
      selectMonths: true,
      selectYears: 2
    });
  }
});
