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
    var timers = jQuery('.entry-running');

    timers.each(function() {
        var summary_el = jQuery(this);
        var elapsed_el = jQuery('.elapsed .number', this);
        var total_el   = jQuery('.total .number', this);

        var stop  = new Date();
        var load  = new Date(Date.parse(summary_el.attr('load_time')));
        var start = new Date(Date.parse(summary_el.attr('start_time')));
        var total_duration = parseFloat(summary_el.attr('total_duration'));


        if (summary_el.hasClass('span-running')) {
            var duration = (stop.getTime() - start.getTime()) / 3600000;
            var new_elapsed = Qublog.Journal.formatHours(duration);
            elapsed_el.text(new_elapsed)
        }

        var duration_since = (stop.getTime() - load.getTime()) / 3600000;
        var new_total = Qublog.Journal.formatHours(total_duration + duration_since);
        total_el.text(new_total);
    });
};

Qublog.Journal.updateJournalThingyButton = function() {
    jQuery.get('/journal/thingy_button', { task_entry: jQuery(this).val() },
        function(data) {
            console.log(data);
            if (data.match(/^(?:Post|Start|Restart|Comment|Taskinate)$/)) {
                jQuery('.new_comment_entry_submit').val(data);
            }
        }
    );
};

Qublog.Journal.handleEnter = function(event) {

    // If Enter pressed, we want to do something
    if (event.keyCode == 13) {
        
        // With the shift key, make sure the textarea gets a return
        if (event.shiftKey) {
            jQuery(this).append(document.createTextNode("\n"));
        }

        // By itself, click the button
        else if (Jifty.Form.Element.clickDefaultButton(event.target)) {
            event.preventDefault();
        }
    }
};

jQuery(document).ready(function() { 
    setInterval(Qublog.Journal.updateActiveTimers, 5000); 
});

Behaviour.register({
    'textarea.argument-name': function(e) {
        jQuery(e).autogrow();
    },
    'textarea.argument-comment': function(e) {
        jQuery(e).keypress(Qublog.Journal.handleEnter)
                 .autogrow()
                 .focus();
    },
    'input.argument-task_entry': function(e) {
        jQuery(e).change(Qublog.Journal.updateJournalThingyButton);
    },
    'div.item': function(e) {
        jQuery('.links', e).css({ visibility: 'hidden' });
        jQuery(e)
            .mouseover(function() {jQuery('.links', this).css({ visibility: 'visible' })})
            .mouseout(function() {jQuery('.links', this).css({ visibility: 'hidden' })});
    }
});
