$(document).ready(function() {
  $('.shop-link').click(function(e) {
    $('#sidebar').show();
    e.preventDefault();
  });

  $('.close-sidebar-link').click(function(e) {
    $('#sidebar').hide();
    e.preventDefault();
  });
});
