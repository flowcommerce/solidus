// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery_ujs
//= require spree/frontend
//= require_tree .

window.toggleSidebar = function() {
  var paypal_button = $('#paypal-button')

  $('#sidebar-pannel, #sidebar-button').toggle();

  if ($('#sidebar-pannel').is(':visible')) {
    paypal_button.hide();
  } else {
    paypal_button.show();
  }
}

$(function(){
  $('#sidebar-pannel .close, #sidebar-button').click(toggleSidebar);
});


