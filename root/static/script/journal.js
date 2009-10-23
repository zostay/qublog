;(function(){

$(window).ready(function() {
    $('div.item')
        .mouseover(function() {$('.links', this).css({ visibility: 'visible' })})
        .mouseout(function() {$('.links', this).css({ visibility: 'hidden' })})
        .find('.links').css({ visibility: 'hidden' });

    $('input#new_task_entry')
        .focus(function() { $(this).select() });

    $('textarea#new_comment')
        .keypress(function(evt) {
            if (evt.keyCode == 13 && evt.shiftKey) {
                $('#new_comment_entry-submit').click();
                return false;
            }
        })
        .focus();
});

})();
