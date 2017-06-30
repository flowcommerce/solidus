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
  // if ($('#sidebar-pannel:visible')[0]) {
  $('#sidebar-pannel, #sidebar-button').toggle();
}

window.toggleSearch = function() {
  var form = '#top-nav .options form';
  $(form).toggleClass('hidden');

  if ($(form + ':visible')[0]) {
    var input = form + ' input[name=keywords]'
    $(input).focus().val($(input).val());
  }
}

window.Popup = {
  open:  function() { $('#popup, #popup-bg').show(); },
  close: function() { $('#popup, #popup-bg').hide(); }
}

$(function(){
  $('#sidebar-pannel .close, #sidebar-button').click(toggleSidebar);

  $('#search-button').click(toggleSearch);

  $('#top-nav input[name=keywords]').blur(toggleSearch);

  $('#sidebar-pannel .search-button').click(function(){
    form = '#sidebar-pannel form';
    $(form).toggle();

    if ($(form+':visible')[0]) {
      var input = form + ' input[name=keywords]'
      $(input).focus().val($(input).val());
    }
  });

  if (/&keywords=\w/.test(location.href)) {
    toggleSearch();
  }
});


