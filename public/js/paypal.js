(function() {

  window.FlowPayPal = {};

  FlowPayPal.client = {
    sandbox:    'not-defined',
    production: 'not-defined'
  }

  FlowPayPal.bind = function(button_id) {
    paypal.Button.render({
      env: FlowPayPal.opts.environment,

      client: FlowPayPal.opts.client,

      commit: true,

      style: {
        label: 'checkout',
        size:  'responsive',
        shape: 'rect',
        color: 'gold',
      },

      payment: function(resolve, reject) {
        $.post('/flow/paypal_id?order=' + FlowPayPal.opts.order).always(function(response){
          if (!response.paypal || response.state == 500) {
            message = response.responseJSON.message || 'Server error';
            alert(message);
            reject(message);
          } else {
            paypal_id = response.paypal.payment_id

            if (paypal_id.indexOf('PAY-') > -1) {
              resolve(paypal_id);
            } else {
              reject('Invalid PayPal ID')
            }
          }
        })
      },

      onAuthorize: function(data, actions) {
        // console.log(data, actions);
        // alert('onAuthorize called');

        return actions.payment.get().then(function(paymentDetails) {
          console.log(paymentDetails);
          return actions.payment.execute().then(function(paymentData) {
            $.post('/flow/paypal_finish?order=' + FlowPayPal.opts.order, function(response) {
              if (response.order_number) {
                location.href = '/orders/' + response.order_number
              } else {
                alert(response.error);
              }
            });
          });
        });
      },

      onCancel: function() {
        console.log('PayPal: canceled');
        return undefined;
      },

      onError: function(data, msg) {
        console.log('PayPal: error', data);
        return undefined;
      }

    }, button_id);
  }

})();