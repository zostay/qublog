;(function(){

$(window).ready(function() {
    setTimeout(function() {
        $('#messages .info, #messages .warning, #messages .error').fadeOut('slow');
    }, 10000);
});

})();
