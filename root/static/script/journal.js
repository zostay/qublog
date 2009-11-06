;(function(){

function formatTime(time) {
    return (time.getHours() % 12 || 12) + ':' 
         + (time.getMinutes() < 10 ? '0' : '') + time.getMinutes()
         + (time.getHours() >= 12 ? ' PM' : ' AM');
}

function formatHours(duration) {
    return (Math.round(duration * 100) / 100).toFixed(2);
}

function updateActiveTimers() {
    var day_summary_total = 0;

    $('.entry-running').each(function() {
        var summary_el   = $(this);
		var timestamp_el = summary_el.find('.timestamp .o-time');
        var elapsed_el   = summary_el.find('.elapsed .number');
        var total_el     = summary_el.find('.total .number');

        var stop  = new Date();
        var load  = new Date(Date.parse(summary_el.attr('load_time')));
        var start = new Date(Date.parse(summary_el.attr('start_time')));
        var total_duration = parseFloat(summary_el.attr('total_duration'));

        if (summary_el.hasClass('span-running')) {
            var duration = (stop.getTime() - start.getTime()) / 3600000;
            day_summary_total += duration;
            var new_elapsed = formatHours(duration);
            elapsed_el.text(new_elapsed)

            timestamp_el.text(formatTime(new Date()));
        }
        else {
            var duration = parseFloat(summary_el.attr('elapsed_duration'));
            day_summary_total += duration;
        }

        var duration_since = (stop.getTime() - load.getTime()) / 3600000;
        var new_total = total_duration + duration_since;
        total_el.text(formatHours(new_total));

    });

    $('.entry-stopped').each(function() {
        var summary_el = $(this);
        var total = parseFloat(summary_el.attr('elapsed_duration'));
        day_summary_total += total;
    });

    $('.day-summary').each(function() {
        var summary_el  = $(this);
        var quitting_el = summary_el.find('.quit .time');
        var total_el    = summary_el.find('.total .number');
        var to_go_el    = summary_el.find('.remaining .number');

        var to_go_hours = Math.max(0, 8.0 - day_summary_total);
        var hours       = Math.floor(to_go_hours);
        var minutes     = Math.floor((to_go_hours - hours) * 60);

        var quitting_time = new Date();
        var quitting_hour = quitting_time.getHours() + hours;
        var quitting_min  = quitting_time.getMinutes() + minutes;

        if (quitting_min >= 60) {
            quitting_hour++;
            quitting_min %= 60;
        }
        
        if (quitting_hour >= 24) {
            quitting_hour = 23;
            quitting_min  = 59;
        }

        quitting_time.setHours(quitting_hour);
        quitting_time.setMinutes(quitting_min);

        if (to_go_hours == 0) {
            quitting_el.text('-:--');
        }
        else {
            quitting_el.text(formatTime(quitting_time));
        }
        total_el.text(formatHours(day_summary_total));
        to_go_el.text(formatHours(to_go_hours));
    });
};

$(document).ready(function() {

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
        });

    if ($('input#new_task_entry').val()) {
        $('textarea#new_comment').focus();
    }

    else {
        $('input#new_task_entry').focus();
    }

    setInterval(updateActiveTimers, 5000); 
});

})();
