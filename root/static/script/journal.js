;(function(){

$(window).ready(function() {
    $('div.item')
        .mouseover(function() {jQuery('.links', this).css({ visibility: 'visible' })})
        .mouseout(function() {jQuery('.links', this).css({ visibility: 'hidden' })})
        .find('.links').css({ visibility: 'hidden' });
});

})();
