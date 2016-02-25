$(document).on('ready page:change', function() {
  // Materialize initialization
  // materialize dropdown menu init
  $(".dropdown-button").dropdown({
    hover: true,
    belowOrigin: true
  });

  // sidebar menu collapses to a button on mobile
  $(".button-collapse").sideNav();

  // materialize accordion init
  $('.collapsible').collapsible();

  // materialize parallax init
  $('.parallax').parallax();

  // materialize wave effect init
  Waves.displayEffect();

  // materialize selectbox init
  $('select').material_select();

  // allow materialize toast to be dismissed on click instead of just the default swipe
  $(document).on('click', '#toast-container .toast', function() {
    $(this).fadeOut(function(){
      $(this).remove();
    });
  });

  // Event listeners
  setup();
});


function setup() {
  addEventListeners();
}

function addEventListeners() {
  addClickListeners();
}


function addClickListeners() {
  $(".close").click(function(e){
    utility.animations.removeEl($(e.currentTarget).parent())
  });
  
  $(".landing-section .start-btn").click(function(e){
    var offset = $(".landing-section.splash").height();
    $("body").animate({ scrollTop: offset });
  });
}