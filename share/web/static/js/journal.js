if (!window.Qublog)  window.Qublog  = {};
if (!Qublog.Journal) Qublog.Journal = {};

Qublog.Journal.formatTime = function(time) {
    return (time.getHours() % 12 || 12) + ':' 
         + (time.getMinutes() < 10 ? '0' : '') + time.getMinutes()
         + (time.getHours() >= 12 ? ' PM' : ' AM');
}

Qublog.Journal.formatHours = function(duration) {
    return (Math.round(duration * 100) / 100).toFixed(2);
}

Qublog.Journal.updateActiveTimers = function() {
    var day_summary_total = 0;

    jQuery('.entry-running').each(function() {
        var summary_el   = jQuery(this);
        var timestamp_el = jQuery('.timestamp .time', this);
        var elapsed_el   = jQuery('.elapsed .number', this);
        var total_el     = jQuery('.total .number', this);

        var stop  = new Date();
        var load  = new Date(Date.parse(summary_el.attr('load_time')));
        var start = new Date(Date.parse(summary_el.attr('start_time')));
        var total_duration = parseFloat(summary_el.attr('total_duration'));

        if (summary_el.hasClass('span-running')) {
            var duration = (stop.getTime() - start.getTime()) / 3600000;
            day_summary_total += duration;
            var new_elapsed = Qublog.Journal.formatHours(duration);
            elapsed_el.text(new_elapsed)

            timestamp_el.text(Qublog.Journal.formatTime(new Date()));
        }
        else {
            var duration = parseFloat(summary_el.attr('elapsed_duration'));
            day_summary_total += duration;
        }

        var duration_since = (stop.getTime() - load.getTime()) / 3600000;
        var new_total = total_duration + duration_since;
        total_el.text(Qublog.Journal.formatHours(new_total));

    });

    jQuery('.entry-stopped').each(function() {
        var summary_el = jQuery(this);
        var total = parseFloat(summary_el.attr('elapsed_duration'));
        day_summary_total += total;
    });

    jQuery('.day-summary').each(function() {
        var summary_el  = jQuery(this);
        var quitting_el = jQuery('.quit .time', this);
        var total_el    = jQuery('.total .number', this);
        var to_go_el    = jQuery('.remaining .number', this);

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
            quitting_el.text(Qublog.Journal.formatTime(quitting_time));
        }
        total_el.text(Qublog.Journal.formatHours(day_summary_total));
        to_go_el.text(Qublog.Journal.formatHours(to_go_hours));
    });
};

Qublog.Journal.updateJournalThingyButton = function() {
    jQuery.get('/journal/thingy_button', { task_entry: jQuery(this).val() },
        function(data) {
            if (data.match(/^(?:Post|Start|Restart|Comment|Taskinate)$/)) {
                jQuery('.new_comment_entry_submit')
                    .removeClass('v-comment v-taskinate v-post v-start v-restart')
                    .addClass('v-' + data.toLowerCase())
                    .val(data);
            }
        }
    );
};

Qublog.Journal.handleEnter = function(event) {

    // If Enter pressed, we want to do something
    if (event.keyCode == 13) {
        
        // With the shift key, click the button
        if (event.shiftKey && Jifty.Form.Element.clickDefaultButton(event.target)) {
            event.preventDefault();
        }

        // By itself, make sure the textarea gets a return
        else {
            jQuery(this).append(document.createTextNode("\n"));
        }
    }
};

jQuery(document).ready(function() { 
    setInterval(Qublog.Journal.updateActiveTimers, 5000); 
});

Behaviour.register({
    'input.argument-date': function(e) {
        jQuery(e).change(function(event) {
            Jifty.Form.Element.clickDefaultButton(event.target);
        });
    },
    'textarea.argument-name': function(e) {
        jQuery(e).keypress(Qublog.Journal.handleEnter)
                 .autogrow()
                 .focus();
    },
    'textarea.argument-comment': function(e) {
        jQuery(e).keypress(Qublog.Journal.handleEnter)
                 .autogrow()
                 .focus();
    },
    'input.argument-task_entry': function(e) {
        jQuery(e).change(Qublog.Journal.updateJournalThingyButton);
        jQuery(e).focus(function() { jQuery(this).select() });
    },
    'div.item': function(e) {
        jQuery('.links', e).css({ visibility: 'hidden' });
        jQuery(e)
            .mouseover(function() {jQuery('.links', this).css({ visibility: 'visible' })})
            .mouseout(function() {jQuery('.links', this).css({ visibility: 'hidden' })});
    }
});
