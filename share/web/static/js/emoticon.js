(function($) {
    $.fn.smiley = function() {
        this.filter('span,img').click(function() {
            if ($(this).is('img')) {
                $('<span class="smiley"/>')
                    .text($(this).attr('title'))
                    .attr({ src: $(this).attr('src') })
                    .smiley()
                    .replaceAll(this);
            }
            else if ($(this).is('span')) {
                $('<img class="smiley"/>')
                    .attr({ src: $(this).attr('src'), title: $(this).text() })
                    .smiley()
                    .replaceAll(this);
            }
        });

        return this;
    };

    $(document).ready(function() {
        $('.smiley').smiley();
    });
})(jQuery);
