// updates current order in custom flow route
window.CurrentOrder = {
  update: function(name, value) {
    if (window.in_reload) { return; }
    window.in_reload = true;

    $('#loader').show();

    $.post('/flow/update_current_order',
      {
        number: window.app.state.order_number,
        name:  name,
        value: value
      },
      function(data) {
        location.href = location.href;
      }
    );
  },
}

// popup is only visible for delivery options
window.Popup = {
  open:  function() {
    var popup = $('#popup');
    popup.before('<div id="popup-bg"></div>')
    popup.show();
  },

  close: function() {
    $('#popup-bg').remove();
    $('#popup').hide();
  },

  select_dd: function(value) {
    CurrentOrder.update('delivered_duty', value);

    Popup.close();

    $('#select-paid, #select-unpaid').hide();
    $('#select-' + value).show();
  }
}
